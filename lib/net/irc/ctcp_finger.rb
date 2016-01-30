require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPFinger < CTCP
      def initialize(text = nil)
        super('FINGER', text)
      end
    end
  end
end
