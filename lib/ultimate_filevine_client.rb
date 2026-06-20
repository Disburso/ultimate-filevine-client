# frozen_string_literal: true

require "faraday"

# Top-level namespace for the Filevine v2 API client.
#
# The gem is designed for concurrent, multitenant use: construct one
# {UltimateFilevineClient::Client} per tenant with that tenant's own
# credentials. There is intentionally NO global/module-level configuration,
# so two tenants never share credential or token state.
#
#   config = UltimateFilevineClient::Configuration.new(
#     client_id: ..., client_secret: ..., pat: ..., region: :us
#   )
#   client = UltimateFilevineClient::Client.new(config: config)
#   client.access_token
module UltimateFilevineClient
  # Base class for every error raised by this gem. Rescue this to catch all
  # gem-originated failures.
  class Error < StandardError; end
end

require_relative "ultimate_filevine_client/version"
require_relative "ultimate_filevine_client/errors"
require_relative "ultimate_filevine_client/region"
require_relative "ultimate_filevine_client/auth/credentials"
require_relative "ultimate_filevine_client/auth/token"
require_relative "ultimate_filevine_client/token_store/base"
require_relative "ultimate_filevine_client/token_store/memory_store"
require_relative "ultimate_filevine_client/configuration"
require_relative "ultimate_filevine_client/auth/authenticator"
require_relative "ultimate_filevine_client/response"
require_relative "ultimate_filevine_client/connection"
require_relative "ultimate_filevine_client/transfer"
require_relative "ultimate_filevine_client/entities/base"
require_relative "ultimate_filevine_client/entities/project"
require_relative "ultimate_filevine_client/entities/contact"
require_relative "ultimate_filevine_client/entities/document"
require_relative "ultimate_filevine_client/entities/note"
require_relative "ultimate_filevine_client/entities/task"
require_relative "ultimate_filevine_client/entities/project_type"
require_relative "ultimate_filevine_client/entities/project_contact"
require_relative "ultimate_filevine_client/entities/deadline"
require_relative "ultimate_filevine_client/entities/deadline_chain"
require_relative "ultimate_filevine_client/entities/team_member"
require_relative "ultimate_filevine_client/entities/appointment"
require_relative "ultimate_filevine_client/entities/collection_item"
require_relative "ultimate_filevine_client/entities/folder"
require_relative "ultimate_filevine_client/entities/user"
require_relative "ultimate_filevine_client/entities/comment"
require_relative "ultimate_filevine_client/entities/share_link"
require_relative "ultimate_filevine_client/entities/report"
require_relative "ultimate_filevine_client/entities/address"
require_relative "ultimate_filevine_client/entities/email"
require_relative "ultimate_filevine_client/entities/phone"
require_relative "ultimate_filevine_client/entities/team"
require_relative "ultimate_filevine_client/entities/hashtag"
require_relative "ultimate_filevine_client/entities/contact_type"
require_relative "ultimate_filevine_client/entities/chain_type"
require_relative "ultimate_filevine_client/pagination/paginator"
require_relative "ultimate_filevine_client/pagination/cursor_paginator"
require_relative "ultimate_filevine_client/resources/base"
require_relative "ultimate_filevine_client/resources/project_scoped"
require_relative "ultimate_filevine_client/resources/projects"
require_relative "ultimate_filevine_client/resources/contacts"
require_relative "ultimate_filevine_client/resources/documents"
require_relative "ultimate_filevine_client/resources/notes"
require_relative "ultimate_filevine_client/resources/tasks"
require_relative "ultimate_filevine_client/resources/project_types"
require_relative "ultimate_filevine_client/resources/folders"
require_relative "ultimate_filevine_client/resources/users"
require_relative "ultimate_filevine_client/resources/appointments"
require_relative "ultimate_filevine_client/resources/comments"
require_relative "ultimate_filevine_client/resources/share_links"
require_relative "ultimate_filevine_client/resources/reports"
require_relative "ultimate_filevine_client/resources/custom_contacts"
require_relative "ultimate_filevine_client/resources/teams"
require_relative "ultimate_filevine_client/resources/contact_types"
require_relative "ultimate_filevine_client/resources/deadline_chain_types"
require_relative "ultimate_filevine_client/resources/project_contacts"
require_relative "ultimate_filevine_client/resources/project_notes"
require_relative "ultimate_filevine_client/resources/project_tasks"
require_relative "ultimate_filevine_client/resources/project_documents"
require_relative "ultimate_filevine_client/resources/project_deadlines"
require_relative "ultimate_filevine_client/resources/project_deadline_chains"
require_relative "ultimate_filevine_client/resources/project_team"
require_relative "ultimate_filevine_client/resources/project_appointments"
require_relative "ultimate_filevine_client/resources/project_emails"
require_relative "ultimate_filevine_client/resources/project_collections"
require_relative "ultimate_filevine_client/resources/project_forms"
require_relative "ultimate_filevine_client/project_scope"
require_relative "ultimate_filevine_client/client"
