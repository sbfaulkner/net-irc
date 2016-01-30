require 'net/irc/reply'

module Net
  class IRC
    # 372 <target> :- <text>
    class RplMotd < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTD', target, text)
      end
    end
  end
end
