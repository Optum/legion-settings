# frozen_string_literal: true

require_relative 'lib/legion/settings/version'

Gem::Specification.new do |spec|
  spec.name = 'legion-settings'
  spec.version       = Legion::Settings::VERSION
  spec.authors       = ['Esity']
  spec.email         = %w[matthewdiverson@gmail.com ruby@optum.com]

  spec.summary       = 'Legion::Settings'
  spec.description   = 'A gem written to handle LegionIO Settings in a consistent way across extensions'
  spec.homepage      = 'https://github.com/Optum/legion-settings'
  spec.license       = 'Apache-2.0'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4'
  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files        = spec.files.select { |p| p =~ %r{^test/.*_test.rb} }
  spec.extra_rdoc_files  = %w[README.md LICENSE CHANGELOG.md]
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/Optum/legion-settings/issues',
    'changelog_uri' => 'https://github.com/Optum/legion-settings/src/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/Optum/legion-settings',
    'homepage_uri' => 'https://github.com/Optum/LegionIO',
    'source_code_uri' => 'https://github.com/Optum/legion-settings',
    'wiki_uri' => 'https://github.com/Optum/legion-settings/wiki'
  }

  spec.add_dependency 'legion-json'
end
