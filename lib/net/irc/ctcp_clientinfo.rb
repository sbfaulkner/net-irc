require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPClientinfo < CTCP
      def initialize(*keywords)
        super('CLIENTINFO', *keywords)
      end
    end
  end
end
