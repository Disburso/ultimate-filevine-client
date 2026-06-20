# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine document (GET /fv-app/v2/Documents).
    class Document < Base
      def id = native_id("DocumentId")
      def filename = self["Filename"]
      def size = self["Size"]
      def folder_id = native_id("FolderId")
      def folder_name = self["FolderName"]
      def project_id = native_id("ProjectId")
      def uploader_id = native_id("UploaderId")
      def upload_date = self["UploadDate"]
      def current_version = self["CurrentVersion"]
      def hashtags = self["Hashtags"]
    end
  end
end
