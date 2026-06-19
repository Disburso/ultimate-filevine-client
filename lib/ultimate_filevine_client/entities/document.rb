# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine document (GET /fv-app/v2/Documents).
    class Document < Base
      def id = native_id("DocumentId")
      def filename = self["Filename"]
      def size = self["Size"]
      def folder_id = native_id("FolderId")
      def project_id = native_id("ProjectId")
    end
  end
end
