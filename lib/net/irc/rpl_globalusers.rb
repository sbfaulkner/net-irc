require 'net/irc/reply_with_target'

module Net
  class IRC
    # 266 <target> :<text>
    class RplGlobalusers < ReplyWithTarget
      def initialize(target, global_users, max_users, text)
        # TODO: may have to handle case of not receiving global and/or max
        @global_users = global_users
        @max_users    = max_users
        super(nil, 'RPL_GLOBALUSERS', target, global_users, max_users, text)
      end
    end
  end
end
