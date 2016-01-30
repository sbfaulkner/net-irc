require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPErrmsg < CTCP
      def initialize(keyword, text = nil)
        super('ERRMSG', keyword, text)
      end
    end
  end
end
