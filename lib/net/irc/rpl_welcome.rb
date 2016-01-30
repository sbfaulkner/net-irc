require 'net/irc/reply_with_target'

module Net
  class IRC
    # 001 <target> :Welcome to the Internet Relay Network <nick>!<user>@<host>
    class RplWelcome < ReplyWithTarget
      def initialize(target, text)
        super(nil, 'RPL_WELCOME', target, text)
      end
    end
  end
end
