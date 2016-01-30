require 'net/irc/reply_with_target'

module Net
  class IRC
    # 255 <target> :<text>
    class RplLuserme < ReplyWithTarget
      def initialize(target, text)
        super(nil, 'RPL_LUSERME', target, text)
      end
    end
  end
end
