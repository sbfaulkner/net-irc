require 'net/irc/reply_with_registry_parameters'

module Net
  class IRC
    # 902 <target> <id> <username> <hostname> :You are now logged out. (id <id>, username <username>, hostname <hostname>)
    class RplLoggedout < ReplyWithRegistryParameters
      def initialize(target, id, username, hostname, text)
        super(nil, 'RPL_LOGGED_OUT', target, id, username, hostname, text)
      end
    end
  end
end
