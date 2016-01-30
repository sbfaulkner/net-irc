require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPVersion < CTCP
      def initialize(*parameters)
        super('VERSION', parameters)
      end
    end
  end
end
