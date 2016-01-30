require 'net/irc/reply_with_target'

module Net
  class IRC
    # 901 <target> <id> <username> <hostname> :You are now logged in. (id <id>, username <username>, hostname <hostname>)
    class ReplyWithRegistryParameters < ReplyWithTarget
      attr_accessor :id, :username, :hostname

      def initialize(prefix, command, target, id, username, hostname, text)
        @id = id
        @username = username
        @hostname = hostname

        super(prefix, command, target, id, username, hostname, text)
      end
    end
  end
end
