require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPPlay < CTCP
      def initialize(filename, mime_type)
        super('PLAY', filename, mime_type)
      end
    end
  end
end
