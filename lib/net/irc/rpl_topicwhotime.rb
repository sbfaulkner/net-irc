require 'net/irc/reply_with_channel'

module Net
  class IRC
    # 333 <target> <channel> <nickname> <time>
    class RplTopicwhotime < ReplyWithChannel
      attr_accessor :nickname, :time

      def initialize(target, channel, nickname, time)
        @nickname = nickname
        @time = Time.at(time.to_i)
        super(nil, 'RPL_TOPICWHOTIME', target, channel, nickname, time, nil)
      end
    end
  end
end
