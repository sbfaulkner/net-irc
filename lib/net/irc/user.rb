require 'net/irc/message'

module Net
  class IRC
    # USER <user> <mode> <unused> <realname>
    class User < Message
      MODE_DEFAULT         = 0
      MODE_RECEIVE_WALLOPS = 4
      MODE_INVISIBLE       = 8

      attr_accessor :user, :realname, :mode

      def initialize(*args)
# puts ">>>>> User#initialize(#{args.inspect})"
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)" if args.size < 2
        raise ArgumentError, "wrong number of arguments (#{args.size} for 4)" if args.size > 4

        @user = args.shift

        # treat mode and "unused" as optional for convenience
        @mode = args.size > 1 && args.shift || MODE_DEFAULT

        args.shift if args.size > 1

        @realname = args.shift

# puts ">>>>> @user=#{@user.inspect}, @mode=#{@mode.inspect}, unused=#{unused.inspect}, @realname=#{@realname.inspect}"
        super(nil, 'USER', @user, @mode, '*', @realname)
# puts ">>>>> prefix=#{prefix.inspect}, command=#{command.inspect}, parameters=#{parameters.inspect}"
      end
    end
  end
end
