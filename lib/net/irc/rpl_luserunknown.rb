require 'net/irc/reply_with_count'

module Net
  class IRC
    # 253 <target> <count> :<text>
    class RplLuserunknown < ReplyWithCount
      def initialize(target, count, text)
        super(nil, 'RPL_LUSERUNKNOWN', target, count, text)
      end
    end
  end
end
