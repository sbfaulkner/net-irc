require 'net/irc/message'

module Net
  class IRC
    # NOTICE <target> <text>
    class Notice < Message
      attr_accessor :target, :text, :ctcp

      def initialize(target, text)
        @target = target
        @text, @ctcp = CTCP.parse(text)

        super(nil, 'NOTICE', @target, text)
      end
    end
  end
end
