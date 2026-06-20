# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Documents resource (/fv-app/v2/Documents).
    #
    # Beyond metadata CRUD, this handles the presigned-URL byte-transfer flow:
    # the gateway returns a short-lived S3 URL, and the file bytes are PUT/GET
    # directly to/from S3 over a separate {Transfer} connection (no Filevine auth
    # headers). #upload and #download wrap the multi-step flow; the lower-level
    # methods (create_upload_url, download_locator, batch_*) expose each step.
    class Documents < Base
      PATH = "/fv-app/v2/Documents"
      # Sibling top-level paths (NOT under /Documents) for search/series/recent.
      SEARCH_PATH = "/fv-app/v2/DocumentSearch"
      RECENT_PATH = "/fv-app/v2/RecentlyOpenedDocuments"
      SERIES_PATH = "/fv-app/v2/DocumentSeries"
      SERIES_META_PATH = "/fv-app/v2/DocumentSeries/Meta"

      def initialize(client)
        super
        @transfer = Transfer.new(config: client.config)
      end

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Document, limit:, **params)
      def get(document_id) = fetch_entity("#{PATH}/#{document_id}", Entities::Document)
      def update(document_id, attributes) = update_entity("#{PATH}/#{document_id}", Entities::Document, attributes)

      # @return [true] on success (a non-2xx response raises a RequestError).
      def delete(document_id) = delete_path("#{PATH}/#{document_id}")

      # --- Search & listing (auto-paging Document collections) ---

      # Search a project's documents by filename. `search_term` and `project_id`
      # are required; pass `folder_id:` (native id only) or other filters via
      # params. Offset/limit paged.
      def search(search_term:, project_id:, limit: Pagination::DEFAULT_LIMIT, **params)
        query = params.merge(searchTerm: search_term, projectId: project_id)
        list_entities(SEARCH_PATH, Entities::Document, limit:, **query)
      end

      # Documents the current user has recently opened. `projectId:` (optional)
      # scopes to a project; omitted, it spans the org (needs Org Admin).
      def recent(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(RECENT_PATH, Entities::Document, limit:, **params)
      end

      # The document series feed (filterable by date range, project, folder, tag).
      # Cursor-paged: the response's LastID is carried back as the next lastId.
      def series(limit: Pagination::DEFAULT_LIMIT, **params)
        cursor_paginate(
          SERIES_PATH,
          items_key: "Items", cursor_param: :lastId, next_cursor_key: "LastID",
          params: params, limit: limit
        ) { |item| Entities::Document.new(item) }
      end

      # Series metadata for the same filters: { "Count", "MinDocId", "MaxDocId" }
      # (use MinDocId-1 as the first lastId, stop once LastID reaches MaxDocId).
      def series_meta(**params) = connection.get(SERIES_META_PATH, params: params).body

      # --- High-level byte transfer ---

      # Upload `io` (a String of bytes or an object responding to #read) as a new
      # document: requests an upload URL, PUTs the bytes to S3, and — when a
      # project is given — commits it via Add Document to Project (without that
      # commit the document stays pending and won't appear in listings).
      # Returns the upload locator hash (includes "DocumentId").
      def upload(io, filename:, project_id: nil, folder_id: nil, content_type: nil)
        bytes = io.respond_to?(:read) ? io.read : io.to_s
        locator = create_upload_url(upload_body(filename, bytes.bytesize, project_id, folder_id))
        @transfer.put(locator["Url"], bytes, content_type: content_type || locator["ContentType"])
        commit_upload(locator, project_id) if project_id
        locator
      end

      # Download a document's bytes. Returns a String of raw bytes.
      def download(document_id)
        @transfer.get(download_locator(document_id).fetch("Url"))
      end

      # --- Low-level steps (return the raw gateway payloads) ---

      # Request a presigned upload URL (DocumentUploadLocator: Url/DocumentId/ContentType).
      def create_upload_url(attributes) = connection.post(PATH, body: attributes).body

      # Presigned download locator (DocumentFileLocator: Url/ContentType/...).
      def download_locator(document_id) = connection.get("#{PATH}/#{document_id}/locator").body

      # Batch presigned upload URLs (array of DocumentUploadResponse).
      def batch_upload(attributes) = connection.post("#{PATH}/batch/upload", body: attributes).body

      # Commit pending batch uploads. Returns the server's boolean success flag.
      def confirm_upload(document_ids)
        connection.post("#{PATH}/batch/upload/confirm", body: { DocumentIds: Array(document_ids) }).body
      end

      # Batch presigned download links (array of { DocumentId, DownloadLink, ... }).
      def batch_download(document_ids, time_to_live: nil)
        body = { DocumentIds: Array(document_ids) }
        body[:DownloadUrlTimeToLive] = time_to_live unless time_to_live.nil?
        connection.post("#{PATH}/batch/download", body: body).body
      end

      # Make an already-uploaded pending document a revision of `document_id`.
      def add_revision(document_id, revision_id)
        create_entity("#{PATH}/#{document_id}/Revisions", Entities::Document, identifier(revision_id))
      end

      def lock(document_id) = post_entity("#{PATH}/#{document_id}/lock", Entities::Document)
      def unlock(document_id) = post_entity("#{PATH}/#{document_id}/unlock", Entities::Document)

      # --- Bulk folder/tag operations ---

      # Copy documents and/or folders into a destination. `attributes` carries the
      # required DestinationFolderId plus DocumentIds and/or FolderIds (Identifier
      # objects). Returns the raw bulk-operation result ({ "Message", "Results" });
      # inspect Results[].Status even on success — a 207 means partial failure.
      def copy(attributes) = connection.post("#{PATH}/copy", body: attributes).body

      # Move documents and/or folders. Same body and result shape as #copy.
      def move(attributes) = connection.post("#{PATH}/move", body: attributes).body

      # Bulk-remove a tag from the given documents. `document_ids` are Identifier
      # objects. Returns nil on full success (204) or the multi-status result hash
      # when some documents fail (207).
      def remove_tag(tag_name, document_ids:)
        bulk_request(:delete, "#{PATH}/tags/#{tag_name}", body: { DocumentIds: document_ids })
      end

      private

      def upload_body(filename, size, project_id, folder_id)
        body = { Filename: filename, Size: size }
        body[:ProjectId] = identifier(project_id) if project_id
        body[:FolderId] = identifier(folder_id) if folder_id
        body
      end

      def commit_upload(locator, project_id)
        @client.project(project_id).documents.add(native(locator["DocumentId"]))
      end

      def identifier(value) = value.is_a?(Hash) ? value : { Native: value }
      def native(value) = value.is_a?(Hash) ? value["Native"] : value
    end
  end
end
