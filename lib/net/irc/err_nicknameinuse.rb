require 'net/irc/error'

module Net
  class IRC
    # 422 <target> <nickname> :Nickname is already in use.
    class ErrNicknameinuse < Error
      attr_accessor :nickname

      def initialize(target, nickname, text)
        @nickname = nickname

        super(nil, 'ERR_NICKNAMEINUSE', target, @nickname, text)
      end
    end
  end
end
