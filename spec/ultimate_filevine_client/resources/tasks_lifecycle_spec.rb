# frozen_string_literal: true

# Covers the full Task CRUD + lifecycle on client.tasks: create/update/unassign,
# assign, complete/uncomplete, snooze, and feed pin/unpin. Filevine models a task
# as a Note, so every write returns the full task record (id under NoteId).
RSpec.describe "Task lifecycle" do # rubocop:disable RSpec/DescribeClass
  subject(:client) { UltimateFilevineClient::Client.new(config:) }

  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "s", pat: "p", region: :us, token_store: store, retry_interval: 0
    )
  end
  let(:base) { "https://api.filevineapp.com" }

  before do
    store.write(config.token_key,
                UltimateFilevineClient::Auth::Token.new(value: "tok", expires_at: Time.now + 3600))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "#create" do
    it "POSTs Body + ProjectId and returns the created Task" do
      stub = stub_request(:post, "#{base}/fv-app/v2/tasks")
             .with(body: { "Body" => "Call client", "ProjectId" => { "Native" => 9 } })
             .to_return(ok({ "NoteId" => { "Native" => 5 }, "Body" => "Call client",
                             "ProjectId" => { "Native" => 9 } }))
      task = client.tasks.create(Body: "Call client", ProjectId: { Native: 9 })
      expect([task.id, task.body, task.project_id]).to eq([5, "Call client", 9])
      expect(stub).to have_been_made.once
    end
  end

  describe "#update" do
    it "PATCHes the task body and returns the updated Task" do
      stub = stub_request(:patch, "#{base}/fv-app/v2/tasks/5").with(body: { "Body" => "New body" })
                                                              .to_return(ok({ "NoteId" => { "Native" => 5 },
                                                                              "Body" => "New body" }))
      expect(client.tasks.update(5, Body: "New body").body).to eq("New body")
      expect(stub).to have_been_made.once
    end
  end

  describe "#unassign" do
    it "DELETEs the task and returns the updated (unassigned) Task, not a bare true" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/tasks/5")
             .to_return(ok({ "NoteId" => { "Native" => 5 }, "AssigneeId" => nil }))
      task = client.tasks.unassign(5)
      expect(task).to be_a(UltimateFilevineClient::Entities::Task)
      expect([task.id, task.assignee_id]).to eq([5, nil])
      expect(stub).to have_been_made.once
    end
  end

  describe "#assign" do
    it "PATCHes the assign URL with no body and returns the reassigned Task" do
      stub = stub_request(:patch, "#{base}/fv-app/v2/tasks/5/assign/9")
             .to_return(ok({ "NoteId" => { "Native" => 5 }, "AssigneeId" => { "Native" => 9 } }))
      expect(client.tasks.assign(5, 9).assignee_id).to eq(9)
      expect(stub).to have_been_made.once
    end
  end

  describe "#complete / #uncomplete" do
    it "completes with an optional time entry" do
      stub = stub_request(:post, "#{base}/fv-app/v2/tasks/5/complete")
             .with(body: { "Description" => "Worked", "Hours" => 1.5 })
             .to_return(ok({ "NoteId" => { "Native" => 5 }, "IsCompleted" => true }))
      expect(client.tasks.complete(5, Description: "Worked", Hours: 1.5)).to be_completed
      expect(stub).to have_been_made.once
    end

    it "completes without a body when no time entry is given" do
      stub_request(:post, "#{base}/fv-app/v2/tasks/5/complete")
        .to_return(ok({ "NoteId" => { "Native" => 5 }, "IsCompleted" => true }))
      expect(client.tasks.complete(5)).to be_completed
      expect(a_request(:post, "#{base}/fv-app/v2/tasks/5/complete")
        .with { |req| req.body.to_s.empty? }).to have_been_made.once
    end

    it "uncompletes a task (body-less POST)" do
      stub_request(:post, "#{base}/fv-app/v2/tasks/5/uncomplete")
        .to_return(ok({ "NoteId" => { "Native" => 5 }, "IsCompleted" => false }))
      expect(client.tasks.uncomplete(5)).not_to be_completed
    end
  end

  describe "#snooze" do
    it "PUTs a SnoozeDate (PascalCase) and returns the Task with its new due date" do
      stub = stub_request(:put, "#{base}/fv-app/v2/tasks/5/snooze")
             .with(body: { "SnoozeDate" => "2026-07-01T00:00:00Z" })
             .to_return(ok({ "NoteId" => { "Native" => 5 }, "TargetDate" => "2026-07-01T00:00:00Z" }))
      expect(client.tasks.snooze(5, "2026-07-01T00:00:00Z").target_date).to eq("2026-07-01T00:00:00Z")
      expect(stub).to have_been_made.once
    end
  end

  describe "#pin / #unpin" do
    it "pins the task to the feed (body-less POST) and reflects the pin state" do
      stub_request(:post, "#{base}/fv-app/v2/tasks/5/pin")
        .to_return(ok({ "NoteId" => { "Native" => 5 }, "IsPinnedToFeed" => true }))
      expect(client.tasks.pin(5)).to be_pinned_to_feed
    end

    it "unpins the task from the feed" do
      stub_request(:post, "#{base}/fv-app/v2/tasks/5/unpin")
        .to_return(ok({ "NoteId" => { "Native" => 5 }, "IsPinnedToFeed" => false }))
      expect(client.tasks.unpin(5)).not_to be_pinned_to_feed
    end
  end
end
