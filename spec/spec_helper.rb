begin
  require 'simplecov'
  SimpleCov.start
  if ENV.key?('CODECOV_TOKEN')
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end
rescue LoadError
  puts 'Failed to load file for coverage reports, continuing without it'
end
require 'legion/logging'

require 'bundler/setup'
RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
