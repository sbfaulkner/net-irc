require 'net/irc/reply_with_target'

module Net
  class IRC
    class Error < ReplyWithTarget
    end
  end
end
