require 'bundler/setup'
require 'uktt'
require 'json-schema'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def use_production
  Uktt::Http.use_production
end

def spec_version
  Uktt::Http.spec_version
end

def api_host
  Uktt::Http.api_host
end


def read_file(fixture)
  fixture_path = "spec/fixtures"
  path = File.join(fixture_path, fixture)

  File.read(path)
end

def parse_file(fixture)
  file = read_file(fixture)

  JSON.parse(file)
end
