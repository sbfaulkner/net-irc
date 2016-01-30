require 'net/irc/reply'

module Net
  class IRC
    # 376 <target> :End of MOTD command.
    class RplEndofmotd < Reply
      def initialize(target, text)
        super(nil, 'RPL_ENDOFMOTD', target, text)
      end
    end
  end
end
