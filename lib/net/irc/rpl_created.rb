require 'net/irc/reply_with_target'

module Net
  class IRC
    # 003 <target> :This server was created <date>
    class RplCreated < ReplyWithTarget
      def initialize(target, text)
        super(nil, 'RPL_CREATED', target, text)
      end
    end
  end
end
