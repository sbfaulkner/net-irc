module Net
  class IRC
    class Message
      attr_reader :prefix
      attr_accessor :command, :parameters

      # order is important to support replacing commands (eg. RPL_BOUNCE is superceded by RPL_ISUPPORT)
      COMMAND_MAPS = %w(
        rfc1459
        rfc2812
        isupport
        hybrid
        ircu
        hyperion
      ).map { |name| File.expand_path("map/#{name}.yml", __dir__) }

      def initialize(*args)
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)" if args.size < 2

        # puts ">>>>> args=#{args.inspect}"

        @prefix, @command, *parameters = args
        # puts ">>>>> @prefix=#{@prefix.inspect}, command=#{@command.inspect}, parameters=#{parameters.inspect}"
        @parameters = Array(parameters)
      end

      class Prefix
        attr_accessor :prefix

        PREFIX_REGEX = /^([^!@]+)(?:(?:!([^@]+))?@(.+))?/

        def initialize(prefix)
          @prefix = prefix
          @matches = prefix.match(PREFIX_REGEX)
        end

        def server
          @prefix
        end

        def nickname
          @matches[1]
        end

        def user
          @matches[2]
        end

        def host
          @matches[3]
        end

        def to_s
          @prefix
        end
      end

      def prefix=(value)
        @prefix = value && Prefix.new(value)
      end

      def prefix?
        @prefix
      end

      def to_s
        # puts ">>>>> prefix=#{prefix.inspect}, command=#{command.inspect}, parameters=#{parameters.inspect}"
        str = prefix ? ":#{prefix} " : ""
        str << command
        unless parameters.empty?
          parameters[0..-2].each do |param|
            str << " #{param}"
          end
          str << if parameters.last =~ /^:| /
                   " :#{parameters.last}"
                 else
                   " #{parameters.last}"
                 end
        end
        str
      end

      def write(socket)
        line = to_s
        IRC.logger.debug ">>>>> #{line.inspect}"
        socket.writeline(line)
      end

      class << self
        def parse(line)
          scanner = StringScanner.new(line)

          prefix = scanner.scan(/:([^ ]+) /) && scanner[1]
          command = scanner.scan(/[[:alpha:]]+|\d{3}/)
          params = []
          14.times do
            break unless scanner.scan(/ ([^ :][^ ]*)/)
            params << scanner[1]
          end
          params << scanner[1] if scanner.scan(/ :(.+)/)

          message = nil
          command_name = command.to_i > 0 ? command_for_number(command.to_i) : command

          if command_name
            message_type = command_name.downcase.split('_').map(&:capitalize).join
            if Net::IRC.const_defined?(message_type)
              message_type = Net::IRC.const_get(message_type)
              message = message_type.new(*params)
              message.prefix = prefix
            end
          end

          message || Message.new(prefix, command_name || command, *params)
        end

        def command_for_number(number)
          command_map[number]
        end

        def command_map
          @command_map ||= COMMAND_MAPS.map { |map| YAML.load_file(map) }.reduce(&:merge)
        end
      end
    end
  end
end
