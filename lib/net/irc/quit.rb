require 'net/irc/message'

module Net
  class IRC
    # QUIT [ <text> ]
    class Quit < Message
      attr_accessor :text

      def initialize(text = nil)
        if @text = text
          super(nil, 'QUIT', @text)
        else
          super(nil, 'QUIT')
        end
      end
    end
  end
end
