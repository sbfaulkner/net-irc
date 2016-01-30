require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPTime < CTCP
      attr_accessor :time
      def initialize(*parameters)
        @time = parameters.join(' ')

        super('TIME', *parameters)
      end
    end
  end
end
