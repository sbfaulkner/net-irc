require 'net/irc/reply_with_target'

module Net
  class IRC
    # 005 <target> ( [ "-" ] <parameter> ) | ( <parameter> "=" [ <value> ] ) *( ( [ "-" ] <parameter> ) | ( <parameter> "=" [ <value> ] ) ) :are supported by this server
    class RplIsupport < ReplyWithTarget
      class Parameter
        PARAMETER_REGEX = /^(-)?([[:alnum:]]{1,20})(?:=(.*))?/

        def initialize(param)
          @param = param
          @matches = param.match(PARAMETER_REGEX)
        end

        def name
          @matches[2]
        end

        def value
          @matches[3] || @matches[1].nil?
        end
      end

      def initialize(target, *args)
        raise ArgumentError, "wrong number of arguments (#{1 + args.size} for 3)" if args.size < 2

        @parameters = args[0..-2].collect { |p| Parameter.new(p) }

        super(nil, 'RPL_ISUPPORT', target, *args)
      end
    end
  end
end
