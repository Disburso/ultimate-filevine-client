# frozen_string_literal: true

RSpec.describe UltimateFilevineClient do
  it "has a version number" do
    expect(UltimateFilevineClient::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it "defines a base Error subclassing StandardError" do
    expect(UltimateFilevineClient::Error.ancestors).to include(StandardError)
  end
end
