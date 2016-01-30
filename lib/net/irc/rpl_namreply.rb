require 'net/irc/reply'

module Net
  class IRC
    # 353 <target> ( "=" | "*" | "@" ) <channel> :[ "@" | "+" ] <nick> *( " " [ "@" / "+" ] <nick> )
    class RplNamreply < Reply
      attr_accessor :channel_type, :channel, :names

      def initialize(target, channel_type, channel, names)
        @channel_type = channel_type
        @channel = channel
        @names = names.split(' ')
        super(nil, 'RPL_NAMREPLY', target, @channel_type, @channel, names, nil)
      end
    end
  end
end
