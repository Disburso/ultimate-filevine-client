# frozen_string_literal: true

module UltimateFilevineClient
  # The per-tenant entry point. Construct one Client per tenant from that
  # tenant's {Configuration}; nothing is shared between Client instances.
  #
  #   config = UltimateFilevineClient::Configuration.new(
  #     client_id: ..., client_secret: ..., pat: ..., region: :us
  #   )
  #   client = UltimateFilevineClient::Client.new(config: config)
  #   client.access_token
  #
  # Clients are safe to use concurrently across threads.
  class Client
    # Endpoint that resolves the credential's user + accessible orgs. Needs only
    # the bearer token, so it works before org_id/user_id are known.
    USER_ORGS_PATH = "/fv-app/v2/utils/GetUserOrgsWithToken"

    # Resource accessors -> their classes. Built eagerly (stateless, cheap) so
    # there is no lazy-memo race under concurrent first use.
    RESOURCES = {
      projects: Resources::Projects,
      contacts: Resources::Contacts,
      documents: Resources::Documents,
      notes: Resources::Notes,
      tasks: Resources::Tasks,
      project_types: Resources::ProjectTypes,
      folders: Resources::Folders,
      users: Resources::Users,
      appointments: Resources::Appointments,
      comments: Resources::Comments,
      share_links: Resources::ShareLinks,
      reports: Resources::Reports,
      custom_contacts: Resources::CustomContacts,
      teams: Resources::Teams,
      contact_types: Resources::ContactTypes,
      deadline_chain_types: Resources::DeadlineChainTypes
    }.freeze

    attr_reader :config, :authenticator, :connection, :billing

    def initialize(config:)
      @config = config
      @authenticator = Auth::Authenticator.new(config: config)
      @connection = Connection.new(config: config, authenticator: @authenticator)
      @resources = RESOURCES.transform_values { |klass| klass.new(self) }
      @billing = Billing.new(self)
    end

    # A valid bearer token for this tenant, minted/refreshed as needed.
    # @return [String]
    def access_token
      @authenticator.access_token
    end

    RESOURCES.each_key do |name|
      define_method(name) { @resources.fetch(name) }
    end

    # Low-level request helpers, delegated to the per-tenant connection.
    Connection::HTTP_METHODS.each do |verb|
      define_method(verb) do |path, **kwargs|
        @connection.public_send(verb, path, **kwargs)
      end
    end

    # A project-scoped view exposing nested sub-resources (contacts, deadlines,
    # tasks, team, etc.). Cheap and immutable — build one per call.
    #
    #   client.project(88_123_456).deadlines.list
    #
    # @param project_id [Integer, String] the Native project id
    # @return [ProjectScope]
    def project(project_id)
      ProjectScope.new(self, project_id)
    end

    # Bootstrap: resolve this credential's user and accessible orgs.
    # @return [Hash] parsed { "User" => ..., "Orgs" => [...] }
    def user_orgs
      post(USER_ORGS_PATH).body
    end
  end
end
