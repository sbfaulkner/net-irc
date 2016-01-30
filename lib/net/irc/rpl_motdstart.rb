require 'net/irc/reply'

module Net
  class IRC
    # 375 <target> :- <server> Message of the day -
    class RplMotdstart < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTDSTART', target, text)
      end
    end
  end
end
