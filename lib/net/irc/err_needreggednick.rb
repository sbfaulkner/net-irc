require 'net/irc/error'

module Net
  class IRC
    # 477 <target> <channel> :<text>
    class ErrNeedreggednick < Error
      attr_accessor :channel

      def initialize(target, channel, text)
        @channel = channel

        super(nil, 'ERR_NEEDREGGEDNICK', target, channel, text)
      end
    end
  end
end
