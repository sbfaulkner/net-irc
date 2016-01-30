require 'net/irc/reply_with_target'

module Net
  class IRC
    # 265 <target> :<text>
    class RplLocalusers < ReplyWithTarget
      def initialize(target, local_users, max_users, text)
        # TODO: may have to handle case of not receiving local and/or max
        @local_users = local_users
        @max_users   = max_users
        super(nil, 'RPL_LOCALUSERS', target, local_users, max_users, text)
      end
    end
  end
end
