# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Entities::Project do
  subject(:project) { described_class.new(attributes) }

  let(:attributes) do
    {
      "ProjectId" => { "Native" => 88_123_456, "Partner" => nil },
      "ProjectName" => "Smith v. Acme",
      "ClientName" => "Jane Smith",
      "PhaseName" => "Discovery",
      "ProjectTypeCode" => "PI",
      "Number" => "2026-0042",
      "IsArchived" => false
    }
  end

  it "unwraps the ProjectId Identifier to its Native integer" do
    expect(project.id).to eq(88_123_456)
  end

  it "exposes named fields" do
    expect(project.name).to eq("Smith v. Acme")
    expect(project.client_name).to eq("Jane Smith")
    expect(project.phase).to eq("Discovery")
    expect(project.project_type_code).to eq("PI")
    expect(project.number).to eq("2026-0042")
  end

  it "coerces IsArchived to a boolean predicate" do
    expect(project.archived?).to be(false)
    expect(described_class.new("IsArchived" => true).archived?).to be(true)
  end

  it "keeps the raw payload available via [] and to_h" do
    expect(project["ProjectName"]).to eq("Smith v. Acme")
    expect(project.to_h).to eq(attributes)
  end

  it "compares by class and attributes" do
    expect(project).to eq(described_class.new(attributes.dup))
  end
end
