require 'net/irc/message'

module Net
  class IRC
    # MODE <channel> *( ( "-" / "+" ) *<modes> *<modeparams> )
    class Mode < Message
      attr_accessor :channel, :modes

      def initialize(channel, *parameters)
        @channel = channel
        @modes = parameters.join(' ')

        super(nil, 'MODE', channel, *parameters)
      end
    end
  end
end
