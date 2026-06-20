# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A document folder (GET /fv-app/v2/Folders).
    class Folder < Base
      def id = native_id("FolderId")
      def parent_id = native_id("ParentId")
      def project_id = native_id("ProjectId")
      def name = self["Name"]
      def archived? = self["IsArchived"] == true
      def protected? = self["IsProtected"] == true
    end
  end
end
