require 'net/irc/reply_with_target'

module Net
  class IRC
    # 004 <target> <servername> <version> <available user modes> <available channel modes>
    # …or, as per https://www.alien.net.au/irc/irc2numerics.html
    # 004 <target> <server_name> <version> <user_modes> <chan_modes> <channel_modes_with_params> <user_modes_with_params> <server_modes> <server_modes_with_params>

    class RplMyinfo < ReplyWithTarget
      attr_accessor :servername, :version, :available_user_modes, :available_channel_modes

      # TODO: decipher addition args?
      def initialize(target, servername, version, available_user_modes, available_channel_modes, *args)
        @servername = servername
        @version = version
        @available_user_modes = available_user_modes
        @available_channel_modes = available_channel_modes

        super(nil, 'RPL_MYINFO', target, servername, version, available_user_modes, available_channel_modes, *args)
      end
    end
  end
end
