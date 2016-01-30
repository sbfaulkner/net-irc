require 'net/irc/reply_with_target'

module Net
  class IRC
    class ReplyWithChannel < ReplyWithTarget
      attr_accessor :channel

      def initialize(prefix, command, target, channel, *args)
        @channel = channel
        super(prefix, command, target, @channel, *args)
      end
    end
  end
end
