require 'net/irc/reply_with_count'

module Net
  class IRC
    # 252 <target> <count> :<text>
    class RplLuserop < ReplyWithCount
      def initialize(target, count, text)
        super(nil, 'RPL_LUSEROP', target, count, text)
      end
    end
  end
end
