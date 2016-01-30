require 'net/irc/reply_with_target'

module Net
  class IRC
    # 251 <target> :<text>
    class RplLuserclient < ReplyWithTarget
      def initialize(target, text)
        super(nil, 'RPL_LUSERCLIENT', target, text)
      end
    end
  end
end
