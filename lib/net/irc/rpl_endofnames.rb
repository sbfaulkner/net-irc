require 'net/irc/reply_with_channel'

module Net
  class IRC
    # 366 <target> <channel> :End of /NAMES list
    class RplEndofnames < ReplyWithChannel
      def initialize(target, channel, text)
        super(nil, 'RPL_ENDOFNAMES', target, channel, text)
      end
    end
  end
end
