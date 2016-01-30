require 'net/irc/message'

module Net
  class IRC
    # PING <server> [ <target> ]
    class Ping < Message
      attr_accessor :server, :target

      def initialize(server, target = nil)
        @server = server

        if @target = target
          super(nil, 'PING', @server, @target)
        else
          super(nil, 'PING', @server)
        end
      end
    end
  end
end
