require 'net/irc/message'

module Net
  class IRC
    # PASS <password>
    class Pass < Message
      attr_accessor :password

      def initialize(password)
        @password = password

        super(nil, 'PASS', @password)
      end
    end
  end
end
