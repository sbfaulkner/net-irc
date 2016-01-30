require 'net/irc/message'

module Net
  class IRC
    # JOIN ( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] )
    #      / "0"
    class Join < Message
      attr_accessor :channels, :keys

      def initialize(channels, keys = nil)
        @channels = channels.split(',')
        @keys = keys && keys.split(',')

        if keys
          super(nil, 'JOIN', channels, keys)
        else
          super(nil, 'JOIN', channels)
        end
      end
    end
  end
end
