require 'net/irc/reply'

module Net
  class IRC
    class ReplyWithTarget < Reply
      attr_accessor :target

      def initialize(prefix, command, target, *args)
        @target = target
        super(prefix, command, @target, *args)
      end
    end
  end
end
