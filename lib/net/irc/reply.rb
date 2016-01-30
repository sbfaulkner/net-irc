require 'net/irc/message'

module Net
  class IRC
    class Reply < Message
      attr_accessor :text

      def initialize(_prefix, command, *args)
        args.pop unless @text = args.last
        super(nil, command, *args)
      end
    end
  end
end
