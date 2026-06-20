# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :record do
  desc "Record sandbox cassettes against a live Filevine sandbox org " \
       "(needs FILEVINE_* creds; FILEVINE_RECORD=all to overwrite existing cassettes)"
  task :sandbox do
    ENV["FILEVINE_RECORD"] = "once" if ENV["FILEVINE_RECORD"].to_s.strip.empty?
    sh "bundle exec rspec --tag sandbox"
  end
end
