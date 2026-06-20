# frozen_string_literal: true

module UltimateFilevineClient
  # A project-scoped view over the API, obtained via {Client#project}.
  #
  #   scope = client.project(88_123_456)
  #   scope.contacts.list
  #   scope.deadlines.create(Name: "Answer due", DueDate: "2026-07-01T00:00:00Z")
  #   scope.collections("Damages").list
  #
  # Lightweight and immutable: a fresh ProjectScope (and its sub-resources) is
  # built per {Client#project} call, so it is cheap to create and safe to use
  # across threads.
  class ProjectScope
    # Sub-resource accessors -> their classes, built eagerly per scope.
    SUBRESOURCES = {
      contacts: Resources::ProjectContacts,
      notes: Resources::ProjectNotes,
      tasks: Resources::ProjectTasks,
      documents: Resources::ProjectDocuments,
      deadlines: Resources::ProjectDeadlines,
      deadline_chains: Resources::ProjectDeadlineChains,
      team: Resources::ProjectTeam,
      appointments: Resources::ProjectAppointments,
      emails: Resources::ProjectEmails
    }.freeze

    # The project's Native id.
    attr_reader :id

    def initialize(client, project_id)
      @client = client
      @id = project_id
      @subresources = SUBRESOURCES.transform_values { |klass| klass.new(client, project_id) }
    end

    SUBRESOURCES.each_key do |name|
      define_method(name) { @subresources.fetch(name) }
    end

    # The project record itself (GET /fv-app/v2/Projects/{id}).
    def get = @client.projects.get(@id)

    # Project vitals — an untyped array of vital fields (raw).
    def vitals = connection.get("/fv-app/v2/Projects/#{@id}/Vitals").body

    # Custom collection (sub-table) for a section selector.
    def collections(selector) = Resources::ProjectCollections.new(@client, @id, selector)

    # Static form section for a selector.
    def forms(selector) = Resources::ProjectForms.new(@client, @id, selector)

    # Create a guest user on this project; returns the raw GuestUser hash.
    def add_guest_user(attributes)
      connection.post("/fv-app/v2/projects/#{@id}/guestusers", body: attributes).body
    end

    # Toggle a section's visibility on this project. Returns true on success.
    def toggle_section_visibility(section_selector:, section_visibility:)
      connection.post(
        "/fv-app/v2/projects/#{@id}/sectionvisibility",
        body: { SectionSelector: section_selector, SectionVisibility: section_visibility }
      )
      true
    end

    private

    def connection = @client.connection
  end
end
