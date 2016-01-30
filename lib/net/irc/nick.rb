require 'net/irc/message'

module Net
  class IRC
    # NICK <nickname>
    class Nick < Message
      attr_accessor :nickname

      def initialize(nickname)
        @nickname = nickname

        super(nil, 'NICK', @nickname)
      end
    end
  end
end
