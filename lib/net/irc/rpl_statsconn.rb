require 'net/irc/reply_with_target'

module Net
  class IRC
    # 250 <target> :<text>
    class RplStatsconn < ReplyWithTarget
      def initialize(target, text)
        super(nil, 'RPL_LSTATSCONN', target, text)
      end
    end
  end
end
