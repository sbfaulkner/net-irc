require 'net/irc/reply'

module Net
  class IRC
    # 002 <target> :Your host is <servername>, running version <ver>
    class RplYourhost < Reply
      def initialize(target, text)
        super(nil, 'RPL_YOURHOST', target, text)
      end
    end
  end
end
