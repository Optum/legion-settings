require 'socket'
require 'legion/settings/os'

module Legion
  module Settings
    class Loader
      include Legion::Settings::OS

      class Error < RuntimeError; end
      attr_reader :warnings, :errors, :loaded_files, :settings

      def initialize
        @warnings = []
        @errors = []
        @settings = default_settings
        @indifferent_access = false
        @loaded_files = []
      end

      def client_defaults
        {
          hostname: system_hostname,
          address: system_address,
          name: "#{::Socket.gethostname.tr('.', '_')}.#{::Process.pid}",
          ready: false
        }
      end

      def default_settings
        {
          client: client_defaults,
          cluster: { public_keys: {} },
          crypt: {
            cluster_secret: nil,
            cluster_secret_timeout: 5,
            vault: { connected: false }
          },
          cache: { enabled: true, connected: false, driver: 'dalli' },
          extensions: {},
          reload: false,
          reloading: false,
          auto_install_missing_lex: true,
          default_extension_settings: {
            logger: { level: 'info', trace: false, extended: false }
          },
          logging: {
            level: 'info',
            location: 'stdout',
            trace: true,
            backtrace_logging: true
          },
          transport: { connected: false },
          data: { connected: false }
        }
      end

      def to_hash
        unless @indifferent_access
          indifferent_access!
          @hexdigest = nil
        end
        @settings
      end

      def [](key)
        to_hash[key]
      end

      def hexdigest
        if @hexdigest && @indifferent_access
          @hexdigest
        else
          hash = case legion_service_name
                 when 'client', 'rspec'
                   to_hash
                 else
                   to_hash.reject do |key, _value|
                     key.to_s == 'client'
                   end
                 end
          @hexdigest = Digest::SHA256.hexdigest(hash.to_s)
        end
      end

      def load_env
        load_api_env
      end

      def load_module_settings(config)
        @settings = deep_merge(config, @settings)
      end

      def load_module_default(config)
        merged = deep_merge(@settings, config)
        deep_diff(@settings, merged) unless @loaded_files.empty?
        @settings = merged
      end

      def load_file(file)
        Legion::Logging.debug("Trying to load file #{file}")
        if File.file?(file) && File.readable?(file)
          begin
            contents = read_config_file(file)
            config = contents.empty? ? {} : Legion::JSON.load(contents)
            merged = deep_merge(@settings, config)
            deep_diff(@settings, merged) unless @loaded_files.empty?
            @settings = merged
            # @indifferent_access = false
            @loaded_files << file
          rescue Legion::JSON::ParseError => e
            Legion::Logging.error('config file must be valid json')
            Legion::Logging.debug("file:#{file}, error: #{e}")
          end
        else
          Legion::Logging.warn("Config file does not exist or is not readable file:#{file}")
        end
      end

      def load_directory(directory)
        path = directory.gsub(/\\(?=\S)/, '/')
        if File.readable?(path) && File.executable?(path)
          Dir.glob(File.join(path, '**{,/*/**}/*.json')).uniq.each do |file|
            load_file(file)
          end
        else
          load_error('insufficient permissions for loading', directory: directory)
        end
      end

      def load_client_overrides
        @settings[:client][:subscriptions] ||= []
        if @settings[:client][:subscriptions].is_a?(Array)
          @settings[:client][:subscriptions] << "client:#{@settings[:client][:name]}"
          @settings[:client][:subscriptions].uniq!
          @indifferent_access = false
        else
          Legion::Logging.warn('unable to apply legion client overrides, reason: client subscriptions is not an array')
        end
      end

      def load_overrides!
        load_client_overrides if %w[client rspec].include?(legion_service_name)
      end

      def set_env!
        ENV['LEGION_LOADED_TEMPFILE'] = create_loaded_tempfile!
      end

      def validate
        validator = Validator.new
        @errors += validator.run(@settings, legion_service_name)
      end

      private

      def setting_category(category)
        @settings[category].map do |name, details|
          details.merge(name: name.to_s)
        end
      end

      def definition_exists?(category, name)
        @settings[category].key?(name.to_sym)
      end

      def indifferent_hash
        Hash.new do |hash, key|
          hash[key.to_sym] if key.is_a?(String)
        end
      end

      def with_indifferent_access(hash)
        hash = indifferent_hash.merge(hash)
        hash.each do |key, value|
          hash[key] = with_indifferent_access(value) if value.is_a?(Hash)
        end
      end

      def indifferent_access!
        @settings = with_indifferent_access(@settings)
        @indifferent_access = true
      end

      def load_api_env
        return unless ENV['LEGION_API_PORT']

        @settings[:api] ||= {}
        @settings[:api][:port] = ENV['LEGION_API_PORT'].to_i
        Legion::Logging.warn("using api port environment variable, api: #{@settings[:api]}")
        @indifferent_access = false
      end

      def read_config_file(file)
        contents = IO.read(file)
        if contents.respond_to?(:force_encoding)
          encoding = ::Encoding::ASCII_8BIT
          contents = contents.force_encoding(encoding)
          contents.sub!("\xEF\xBB\xBF".force_encoding(encoding), '')
        else
          contents.sub!(/^\357\273\277/, '')
        end
        contents.strip
      end

      def deep_merge(hash_one, hash_two)
        merged = hash_one.dup
        hash_two.each do |key, value|
          merged[key] = if hash_one[key].is_a?(Hash) && value.is_a?(Hash)
                          deep_merge(hash_one[key], value)
                        elsif hash_one[key].is_a?(Array) && value.is_a?(Array)
                          hash_one[key].concat(value).uniq
                        else
                          value
                        end
        end
        merged
      end

      # rubocop:disable Metrics/AbcSize
      def deep_diff(hash_one, hash_two)
        keys = hash_one.keys.concat(hash_two.keys).uniq
        keys.each_with_object({}) do |key, diff|
          next if hash_one[key] == hash_two[key]

          diff[key] = if hash_one[key].is_a?(Hash) && hash_two[key].is_a?(Hash)
                        deep_diff(hash_one[key], hash_two[key])
                      else
                        [hash_one[key], hash_two[key]]
                      end
        end
      end
      # rubocop:enable Metrics/AbcSize

      def create_loaded_tempfile!
        dir = ENV['LEGION_LOADED_TEMPFILE_DIR'] || Dir.tmpdir
        file_name = "legion_#{legion_service_name}_loaded_files"
        path = File.join(dir, file_name)
        File.open(path, 'w') do |file|
          file.write(@loaded_files.join(':'))
        end
        path
      end

      def legion_service_name
        File.basename($PROGRAM_NAME).split('-').last
      end

      def system_hostname
        Socket.gethostname
      rescue StandardError
        'unknown'
      end

      def system_address
        Socket.ip_address_list.find do |address|
          address.ipv4? && !address.ipv4_loopback?
        end.ip_address
      rescue StandardError
        'unknown'
      end

      def warning(message, data = {})
        @warnings << {
          message: message
        }.merge(data)
        Legion::Logging.warn(message)
      end

      def load_error(message, data = {})
        @errors << {
          message: message
        }.merge(data)
        Legion::Logging.error(message)
        raise(Error, message)
      end
    end
  end
end
