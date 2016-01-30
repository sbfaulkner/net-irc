require 'net/irc/message'

module Net
  class IRC
    # PONG <server> [ <target> ]
    class Pong < Message
      attr_accessor :server, :target

      def initialize(server, target = nil)
        @server = server

        if @target = target
          super(nil, 'PONG', @server, @target)
        else
          super(nil, 'PONG', @server)
        end
      end
    end
  end
end
