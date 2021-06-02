require 'spec_helper'
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
Legion::Logging.setup(log_level: 'warn', level: 'warn', trace: true)
require 'legion/settings'
require 'legion/json'

RSpec.describe Legion::Settings do
  it 'has a version number' do
    expect(Legion::Settings::VERSION).not_to be nil
  end
end

require File.join(File.dirname(__FILE__), 'helpers')

RSpec.describe 'Legion::Settings' do
  include Helpers

  before do
    @assets_dir = File.join(File.dirname(__FILE__), 'assets')
    @config_file = File.join(@assets_dir, 'config.json')
    @config_dir = File.join(@assets_dir, 'conf.d')
    @app_dir = File.join(@assets_dir, 'app')
  end

  it 'can provide a loader' do
    expect(Legion::Settings).to respond_to(:load)
    expect(Legion::Settings.load).to be_an_instance_of(Legion::Settings::Loader)
    settings = Legion::Settings.load
    expect(settings).to respond_to(:validate)
  end

  it 'can provide a loader singleton' do
    singleton = Legion::Settings.get
    expect(Legion::Settings.get).to eq(singleton)
  end

  it 'can override the loader singleton' do
    singleton = Legion::Settings.get
    expect(Legion::Settings.get).to eq(singleton)
    loader = Legion::Settings.load
    expect(singleton).to_not eq(loader)
    Legion::Settings.loader = loader
    expect(Legion::Settings.get).to eq(loader)
  end

  it "can load up a loader if one doesn't exist" do
    settings = Legion::Settings.get
    expect(settings).to be_an_instance_of(Legion::Settings::Loader)
    expect(Legion::Settings.get).to eq(settings)
  end

  it 'can load not set key' do
    expect(Legion::Settings[:transport]).to be_a Hash
    expect(Legion::Settings[:transport]).to be_a Hash
    expect(Legion::Settings[:transport][:not_set]).to be nil
  end

  it 'can load setting category when not set' do
    expect(Legion::Settings[:transport]).to be_a Hash
    expect(Legion::Settings[:transport][:foo]).to be nil
    expect { Legion::Settings[:transport][:foo][:test] }.to raise_error NoMethodError
  end
end
