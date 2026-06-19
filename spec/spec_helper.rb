# frozen_string_literal: true

require "ultimate_filevine_client"

require "webmock/rspec" # disables real network connections by default
require_relative "support/vcr"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.order = :random
  Kernel.srand config.seed
end
