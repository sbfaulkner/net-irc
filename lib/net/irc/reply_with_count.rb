require 'net/irc/reply_with_target'

module Net
  class IRC
    class ReplyWithCount < ReplyWithTarget
      attr_accessor :count

      def initialize(prefix, command, target, count, text)
        @count = count
        super(prefix, command, target, count, text)
      end
    end
  end
end
