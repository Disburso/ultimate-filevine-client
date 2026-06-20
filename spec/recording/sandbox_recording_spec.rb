# frozen_string_literal: true

# A live "recording pass" against a Filevine SANDBOX org — the bridge between the
# hand-authored fixtures and real Filevine behavior. The record/replay machinery
# lives in spec/support/sandbox.rb and spec/support/vcr.rb; the README section
# "Recording against a sandbox org" explains how to run it.
#
# Default run (no FILEVINE_RECORD): replays the committed cassettes offline and
# asserts the client still parses the real response shapes. Each example SKIPS
# until its cassette has been recorded, so the suite stays green before then.
#
# Recording (`rake record:sandbox` with real FILEVINE_* creds): performs the
# requests against the sandbox org and writes the cassettes. The write lifecycle
# archives the project it creates; the synthetic client contact it creates is
# left behind (the v2 API exposes no contact delete).
RSpec.describe "Filevine sandbox recording", :sandbox do # rubocop:disable RSpec/DescribeClass
  # Skip — without touching the network — when we can neither record (no creds)
  # nor replay (no committed cassette); otherwise drive the named cassette.
  def with_cassette(name, &block)
    if SandboxRecording.recording?
      skip "set FILEVINE_CLIENT_ID/SECRET/PAT to record #{name.inspect}" unless SandboxRecording.credentials_present?
    elsif !SandboxRecording.cassette?(name)
      skip "no #{name.inspect} cassette yet — run `rake record:sandbox` against a sandbox org"
    end
    VCR.use_cassette(name, &block)
  end

  it "bootstraps the tenant and reads the core list endpoints" do
    with_cassette("sandbox/read_only") do
      client = SandboxRecording.client

      payload = client.user_orgs
      expect(payload).to include("User", "Orgs")

      tenant = SandboxRecording.tenant_client(client, payload)

      expect(tenant.users.me).to be_a(UltimateFilevineClient::Entities::User)
      expect(tenant.projects.list(limit: 2).first(2))
        .to all(be_a(UltimateFilevineClient::Entities::Project))
      expect(tenant.project_types.list.first(2))
        .to all(be_a(UltimateFilevineClient::Entities::ProjectType))
    end
  end

  it "runs a project write lifecycle and archives the project afterward" do
    with_cassette("sandbox/project_lifecycle") do
      client = SandboxRecording.client
      tenant = SandboxRecording.tenant_client(client, client.user_orgs)

      project_type_id = tenant.project_types.list.first.id
      client_contact = tenant.contacts.create(FirstName: "Ada", LastName: "Sandbox")

      project = tenant.projects.create(
        ProjectName: "UFC recording-pass sandbox",
        ProjectTypeId: { Native: project_type_id },
        ClientId: { Native: client_contact.id }
      )
      project_id = project.id
      expect(project_id).to be_a(Integer)

      begin
        renamed = tenant.projects.update(project_id, ProjectName: "UFC recording-pass sandbox (renamed)")
        expect(renamed.name).to eq("UFC recording-pass sandbox (renamed)")

        note = tenant.notes.create(
          ProjectId: { Native: project_id }, Subject: "Recording pass",
          Body: "Created by the sandbox recording spec."
        )
        expect(note).to be_a(UltimateFilevineClient::Entities::Note)

        task = tenant.tasks.create(Body: "Recording-pass task", ProjectId: { Native: project_id })
        expect(tenant.tasks.complete(task.id).completed?).to be(true)
        tenant.tasks.uncomplete(task.id)
      ensure
        tenant.projects.archive(project_id)
      end
    end
  end
end
