require 'net/irc/reply_with_registry_parameters'

module Net
  class IRC
    # 901 <target> <id> <username> <hostname> :You are now logged in. (id <id>, username <username>, hostname <hostname>)
    class RplLoggedin < ReplyWithRegistryParameters
      def initialize(target, id, username, hostname, text)
        super(nil, 'RPL_LOGGED_IN', target, id, username, hostname, text)
      end
    end
  end
end
