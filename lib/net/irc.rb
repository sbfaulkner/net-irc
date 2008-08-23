require 'net/protocol'
require 'strscan'
require 'yaml'
require 'logger'

module Net
  class IRC < Protocol
    include Enumerable

    class << self
      def logger
        @logger ||= Logger.new('net-irc.log')
      end
      
      def logger=(logger)
        @logger = logger
      end
    end
    
    USER_MODE_DEFAULT = 0
    USER_MODE_RECEIVE_WALLOPS = 4
    USER_MODE_INVISIBLE = 8

    PORT_DEFAULT = 6667

    MESSAGE_NUMBERS = YAML.load_file("#{File.dirname(__FILE__)}/rfc2812.yml")

    class Message
      attr_reader :prefix
      attr_accessor :command, :parameters

      def initialize(*args)
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)" if args.size < 2

# puts ">>>>> args=#{args.inspect}"

        @prefix, @command, *parameters = args
# puts ">>>>> @prefix=#{@prefix.inspect}, command=#{@command.inspect}, parameters=#{parameters.inspect}"
        @parameters = Array(parameters)
      end

      class Prefix
        attr_accessor :prefix
        
        PREFIX_REGEX = /^([^!@]+)(?:(?:!([^@]+))?@(.+))?/
        
        def initialize(prefix)
          @prefix = prefix
          @matches = prefix.match(PREFIX_REGEX)
        end
        
        def server
          @prefix
        end
        
        def nickname
          @matches[1]
        end
        
        def user
          @matches[2]
        end
        
        def host
          @matches[3]
        end
        
        def to_s
          @prefix
        end
      end
      
      def prefix=(value)
        @prefix = value && Prefix.new(value)
      end
      
      def prefix?
        @prefix
      end
      
      def to_s
# puts ">>>>> prefix=#{prefix.inspect}, command=#{command.inspect}, parameters=#{parameters.inspect}"
        str = prefix ? ":#{prefix} " : ""
        str << command
        if ! parameters.empty?
          parameters[0..-2].each do |param|
            str << " #{param}"
          end
          if parameters.last =~ /^:| /
            str << " :#{parameters.last}"
          else
            str << " #{parameters.last}"
          end
        end
        str
      end

      def write(socket)
        line = to_s
        IRC.logger.debug ">>>>> #{line.inspect}"
        socket.writeline(line)
      end

      class << self
        def read(socket)
          line = socket.readline.chomp
          IRC.logger.debug "<<<<< #{line.inspect}"
          scanner = StringScanner.new(line)
          prefix = scanner.scan(/:([^ ]+) /) && scanner[1]
          command = scanner.scan(/[[:alpha:]]+|\d{3}/)
          params = []
          14.times do
            break if ! scanner.scan(/ ([^ :][^ ]*)/)
            params << scanner[1]
          end
          params << scanner[1] if scanner.scan(/ :(.+)/)

          command = MESSAGE_NUMBERS[command.to_i] || 'UNKNOWN' if command.to_i > 0

          message_type = "#{command.downcase.split('_').collect { |w| w.capitalize }.join}"
          
          if Net::IRC.const_defined?(message_type)
            message_type = Net::IRC.const_get(message_type)
            msg = message_type.new(*params)
            msg.prefix = prefix
            msg
          else
            Message.new(prefix, command, *params)
          end
        end
      end
    end

    class Reply < Message
      attr_accessor :target, :text
      
      def initialize(prefix, command, target, *args)
        @target = target
        if @text = args.last
          super(nil, command, @target, *args)
        else
          args.pop
          super(nil, command, @target, *args)
        end
      end
    end

    # 001 <target> :Welcome to the Internet Relay Network <nick>!<user>@<host>
    class RplWelcome < Reply
      def initialize(target, text)
        super(nil, 'RPL_WELCOME', target, text)
      end
    end

    # 002 <target> :Your host is <servername>, running version <ver>
    class RplYourhost < Reply
      def initialize(target, text)
        super(nil, 'RPL_YOURHOST', target, text)
      end
    end

    # 003 <target> :This server was created <date>
    class RplCreated < Reply
      def initialize(target, text)
        super(nil, 'RPL_CREATED', target, text)
      end
    end

    # 004 <target> <servername> <version> <available user modes> <available channel modes>
    class RplMyinfo < Reply
      attr_accessor :servername, :version, :available_user_modes, :available_channel_modes
      
      def initialize(target, servername, version, available_user_modes, available_channel_modes)
        @servername = servername
        @version = version
        @available_user_modes = available_user_modes
        @available_channel_modes = available_channel_modes
        
        super(nil, 'RPL_MYINFO', target, servername, version, available_user_modes, available_channel_modes, nil)
      end
    end

    # 375 <target> :- <server> Message of the day -
    class RplMotdstart < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTDSTART', target, text)
      end
    end

    # 372 <target> :- <text>
    class RplMotd < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTD', target, text)
      end
    end

    # 376 <target> :End of MOTD command.
    class RplEndofmotd < Reply
      def initialize(target, text)
        super(nil, 'RPL_ENDOFMOTD', target, text)
      end
    end
    
    class Error < Reply
    end

    # 422 <target> <nickname> :Nickname is already in use.
    class ErrNicknameinuse < Error
      attr_accessor :nickname
      
      def initialize(target, nickname, text)
        @nickname = nickname
        
        super(nil, 'ERR_NICKNAMEINUSE', target, @nickname, text)
      end
    end
    
    # JOIN ( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] )
    #      / "0"
    class Join < Message
      attr_accessor :channels, :keys

      def initialize(channels, keys = nil)
        @channels = channels.split(',')
        @keys = keys && keys.split(',')

        if keys
          super(nil, 'JOIN', channels, keys)
        else
          super(nil, 'JOIN', channels)
        end
      end
    end

    # NICK <nickname>
    class Nick < Message
      attr_accessor :nickname

      def initialize(nickname)
        @nickname = nickname

        super(nil, 'NICK', @nickname)
      end
    end

    # NOTICE <target> <text>
    class Notice < Message
      attr_accessor :target, :text
      
      def initialize(target, text)
        @target = target
        @text = text
        
        super(nil, 'NOTICE', @target, @text)
      end
    end
    
    # PART <channel> *( "," <channel> ) [ <text> ]
    class Part < Message
      attr_accessor :channels, :text
      
      def initialize(channels, message = nil)
        @channels = channels.split(',')

        if message
          super(nil, 'JOIN', channels, message)
        else
          super(nil, 'JOIN', channels)
        end
      end
    end
    
    # PASS <password>
    class Pass < Message
      attr_accessor :password

      def initialize(password)
        @password = password

        super(nil, 'PASS', @password)
      end
    end

    # PING <server> [ <target> ]
    class Ping < Message
      attr_accessor :server, :target
      
      def initialize(server, target = nil)
        @server = server
        
        if @target = target
          super(nil, 'PING', @server, @target)
        else
          super(nil, 'PING', @server)
        end
      end
    end

    # PONG <server> [ <target> ]
    class Pong < Message
      attr_accessor :server, :target
      
      def initialize(server, target = nil)
        @server = server
        
        if @target = target
          super(nil, 'PONG', @server, @target)
        else
          super(nil, 'PONG', @server)
        end
      end
    end
    
    # PRIVMSG <target> <text>
    class Privmsg < Message
      attr_accessor :target, :text
      
      def initialize(target, text)
        @target = target
        @text = text
        
        super(nil, 'PRIVMSG', @target, @text)
      end
    end
    
    # QUIT [ <text> ]
    class Quit < Message
      attr_accessor :text
      
      def initialize(text = nil)
        if @text = text
          super(nil, 'QUIT', @text)
        else
          super(nil, 'QUIT')
        end
      end
    end
    
    # USER <user> <mode> <unused> <realname>
    class User < Message
      attr_accessor :user, :realname, :mode

      def initialize(*args)
# puts ">>>>> User#initialize(#{args.inspect})"
        raise ArgumentError, "wrong number of arguments (#{args.size} for 2)" if args.size < 2
        raise ArgumentError, "wrong number of arguments (#{args.size} for 4)" if args.size > 4

        @user = args.shift
        
        # treat mode and "unused" as optional for convenience
        @mode = args.size > 1 && args.shift || USER_MODE_DEFAULT
        
        args.shift if args.size > 1
        
        @realname = args.shift

# puts ">>>>> @user=#{@user.inspect}, @mode=#{@mode.inspect}, unused=#{unused.inspect}, @realname=#{@realname.inspect}"
        super(nil, 'USER', @user, @mode, '*', @realname)
# puts ">>>>> prefix=#{prefix.inspect}, command=#{command.inspect}, parameters=#{parameters.inspect}"
      end
    end

    class << self
      def start(user, realname, address, port = nil, &block)
        new(address, port).start(user, realname, &block)
      end
    end

    def initialize(address, port = nil)
      @address = address
      @port = port || PORT_DEFAULT
      @started = false
      @socket = nil
    end

    def started?
      @started
    end

    def start(user, realname, nickname = nil)
      raise IOError, 'IRC session already started' if started?

      if block_given?
        begin
          do_start(user, realname, nickname)
          return yield(self)
        ensure
          do_finish
        end
      else
        do_start(user, realname, nickname)
        return self
      end
    end

    def finish
      raise IOError, 'IRC session not yet started' if ! started?
    end

    def each
      while event = Message.read(@socket)
        yield event
      end
    end

    def join(channels = nil)
      case channels
      when NilClass
        Join.new('0')
      when Hash
        Join.new(channels.keys.join(','), channels.values.join(','))
      when Array
        Join.new(channels.join(','))
      else
        Join.new(channels.to_s)
      end.write(@socket)
    end
    
    def nick(nickname)
      Nick.new(nickname).write(@socket)
    end
    
    def part(channels, message = nil)
      if message
        Part.new(Array(channels).join(','), message)
      else
        Part.new(Array(channels).join(','))
      end.write(@socket)
    end
    
    def pong(server, target = nil)
      Pong.new(server, target).write(@socket)
    end
    
    def privmsg(target, text)
      Privmsg.new(target, text).write(@socket)
    end
    
    def user(user, realname, mode = nil)
      User.new(user, mode || USER_MODE_DEFAULT, realname).write(@socket)
    end

    private
    def do_start(user, realname, nickname = nil)
      @socket = InternetMessageIO.old_open(@address, @port)
      # TODO: Pass.new(password).write(@socket)
      nick(user)
      user(user, realname)
      @started = true
    ensure
      do_finish if ! started?
    end

    def do_finish
    ensure
      @started = false
      @socket.close if @socket && ! @socket.closed?
      @socket = nil
    end
  end
end