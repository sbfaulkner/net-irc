require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPPing < CTCP
      attr_accessor :arg

      def initialize(arg = nil)
        if @arg = arg
          super('PING', arg)
        else
          super('PING')
        end
      end
    end
  end
end
