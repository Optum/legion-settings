require 'legion/json'
require 'legion/settings/version'
require 'legion/json/parse_error'
require 'legion/settings/loader'

module Legion
  module Settings
    class << self
      attr_accessor :loader

      def load(options = {})
        @loader = Legion::Settings::Loader.new
        @loader.load_env
        @loader.load_file(options[:config_file]) if options[:config_file]
        @loader.load_directory(options[:config_dir]) if options[:config_dir]
        options[:config_dirs]&.each do |directory|
          @loader.load_directory(directory)
        end
        @loader
      end

      def get(options = {})
        @loader || @loader = load(options)
      end

      def [](key)
        logger.info('Legion::Settings was not loading, auto loading now!') if @loader.nil?
        @loader = load if @loader.nil?
        @loader[key]
      rescue NoMethodError, TypeError
        logger.fatal 'rescue inside [](key)'
        nil
      end

      def set_prop(key, value)
        @loader = load if @loader.nil?
        @loader[key] = value
      end

      def merge_settings(key, hash)
        @loader = load if @loader.nil?
        thing = {}
        thing[key.to_sym] = hash
        @loader.load_module_settings(thing)
      end

      def logger
        @logger = if ::Legion.const_defined?('Logging')
                    ::Legion::Logging
                  else
                    require 'logger'
                    ::Logger.new($stdout)
                  end
      end
    end
  end
end
