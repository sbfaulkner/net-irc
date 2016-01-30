require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPDcc < CTCP
      def initialize(type, protocol, ip, port, *args)
        super('DCC', type, protocol, ip, port, *args)
      end
    end
  end
end
