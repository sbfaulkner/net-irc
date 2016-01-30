require 'net/irc/message'

module Net
  class IRC
    # PRIVMSG <target> <text>
    class Privmsg < Message
      attr_accessor :target, :text, :ctcp

      def initialize(target, text)
        @target = target
        @text, @ctcp = CTCP.parse(text)

        super(nil, 'PRIVMSG', @target, text)
      end
    end
  end
end
