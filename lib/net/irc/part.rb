require 'net/irc/message'

module Net
  class IRC
    # PART <channel> *( "," <channel> ) [ <text> ]
    class Part < Message
      attr_accessor :channels, :text

      def initialize(channels, message = nil)
        @channels = channels.split(',')

        if message
          super(nil, 'PART', channels, message)
        else
          super(nil, 'PART', channels)
        end
      end
    end
  end
end
