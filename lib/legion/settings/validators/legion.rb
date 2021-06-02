module Legion
  module Settings
    module Validators
      module Legion
        def validate_legion_spawn(legion)
          spawn = legion[:spawn]
          if is_a_hash?(spawn)
            if is_an_integer?(spawn[:limit])
              (spawn[:limit]).positive? ||
                invalid(legion, 'legion spawn limit must be greater than 0')
            else
              invalid(legion, 'legion spawn limit must be an integer')
            end
          else
            invalid(legion, 'legion spawn must be a hash')
          end
        end

        def validate_legion(legion)
          if is_a_hash?(legion)
            validate_legion_spawn(legion)
          else
            invalid(legion, 'legion must be a hash')
          end
        end
      end
    end
  end
end
