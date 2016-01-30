require 'net/irc/reply_with_count'

module Net
  class IRC
    # 254 <target> <count> :<text>
    class RplLuserchannels < ReplyWithCount
      def initialize(target, count, text)
        super(nil, 'RPL_LUSERCHANNELS', target, count, text)
      end
    end
  end
end
