require 'net/irc/reply_with_channel'

module Net
  class IRC
    # 332 <target> <target> <channel> :<text>
    class RplTopic < ReplyWithChannel
      def initialize(target, channel, text)
        super(nil, 'RPL_TOPIC', target, channel, text)
      end
    end
  end
end
