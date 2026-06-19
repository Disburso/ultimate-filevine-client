# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Auth::Token do
  let(:now) { Time.utc(2026, 1, 1, 12, 0, 0) }

  it "builds from a /connect/token response body" do
    token = described_class.from_response({ "access_token" => "abc", "expires_in" => 3600 }, now: now)
    expect(token.value).to eq("abc")
    expect(token.expires_at).to eq(now + 3600)
  end

  it "accepts symbol-keyed bodies" do
    token = described_class.from_response({ access_token: "abc", expires_in: 60 }, now: now)
    expect(token.value).to eq("abc")
  end

  it "is not expired comfortably before expiry" do
    token = described_class.new(value: "x", expires_at: now + 3600)
    expect(token.expired?(now: now)).to be(false)
  end

  it "is considered expired once inside the skew window" do
    token = described_class.new(value: "x", expires_at: now + 30)
    expect(token.expired?(now: now, skew: 60)).to be(true)
  end

  it "raises AuthenticationError when access_token is missing" do
    expect { described_class.from_response({ "expires_in" => 3600 }, now: now) }
      .to raise_error(UltimateFilevineClient::AuthenticationError, /access_token/)
  end
end
