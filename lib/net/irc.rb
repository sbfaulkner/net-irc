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
    
    VERSION = "0.0.2"
    
    class CTCP
      attr_accessor :source, :code, :parameters
      
      CTCP_REGEX = /\001(.*?)\001/
      
      def initialize(code, *parameters)
        @source = nil
        @code = code
        @parameters = parameters
      end
      
      def to_s
        str = "\001#{code}"
        str << parameters.collect { |p| " #{p}"}.join
        str << "\001"
      end
      
      class << self
        def parse(text)
          [
            text.gsub(CTCP_REGEX, ''),
            text.scan(CTCP_REGEX).flatten.collect do |message|
              parameters = message.split(' ')
              case code = parameters.shift
              when 'VERSION'
                CTCPVersion.new(*parameters)
              when 'PING'
                CTCPPing.new(*parameters)
              when 'CLIENTINFO'
                CTCPClientinfo(*parameters)
              when 'ACTION'
                CTCPAction(*parameters)
              else
                CTCP.new(code, *parameters)
              end
            end
          ]
        end
      end
    end
    
    class CTCPVersion < CTCP
      def initialize(*parameters)
        super('VERSION', *parameters)
      end
    end
    
    class CTCPPing < CTCP
      def initialize(*parameters)
        super('PING', *parameters)
      end
    end
    
    class CTCPClientinfo < CTCP
      def initialize(*parameters)
        super('CLIENTINFO', *parameters)
      end
    end
    
    class CTCPAction < CTCP
      def initialize(*parameters)
        super('ACTION', *parameters)
      end
    end
    
    class Message
      attr_reader :prefix
      attr_accessor :command, :parameters

      COMMAND_MAPS = %w(rfc1459 rfc2812 isupport hybrid ircu)

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
        def parse(line)
          scanner = StringScanner.new(line)
          
          prefix = scanner.scan(/:([^ ]+) /) && scanner[1]
          command = scanner.scan(/[[:alpha:]]+|\d{3}/)
          params = []
          14.times do
            break if ! scanner.scan(/ ([^ :][^ ]*)/)
            params << scanner[1]
          end
          params << scanner[1] if scanner.scan(/ :(.+)/)

          message = nil
          command_name = command.to_i > 0 ? command_for_number(command.to_i) : command
        
          if command_name
            message_type = "#{command_name.downcase.split('_').collect { |w| w.capitalize }.join}"
            if Net::IRC.const_defined?(message_type)
              message_type = Net::IRC.const_get(message_type)
              message = message_type.new(*params)
              message.prefix = prefix
            end
          end
        
          message ||= Message.new(prefix, command_name || command, *params)
        end
        
        def command_for_number(number)
          @command_map ||= COMMAND_MAPS.inject({}) { |merged,map| merged.merge!(YAML.load_file("#{File.dirname(__FILE__)}/#{map}.yml")) }
          @command_map[number]
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

    # 005 <target> ( [ "-" ] <parameter> ) | ( <parameter> "=" [ <value> ] ) *( ( [ "-" ] <parameter> ) | ( <parameter> "=" [ <value> ] ) ) :are supported by this server
    class RplIsupport < Reply
      class Parameter
        PARAMETER_REGEX = /^(-)?([[:alnum:]]{1,20})(?:=(.*))?/
        
        def initialize(param)
          @param = param
          @matches = param.match(PARAMETER_REGEX)
        end
        
        def name
          @matches[2]
        end
        
        def value
          @matches[3] || @matches[1].nil?
        end
      end
      
      def initialize(target, *args)
        raise ArgumentError, "wrong number of arguments (#{1 + args.size} for 3)" if args.size < 2
        
        @parameters = args[0..-2].collect { |p| Parameter.new(p) }
        
        super(nil, 'RPL_ISUPPORT', target, *args)
      end
    end
    
    # 250 :<text>
    class RplStatsconn < Reply
      def initialize(target, text)
        super(nil, 'RPL_LSTATSCONN', target, text)
      end
    end
    
    # 251 :<text>
    class RplLuserclient < Reply
      def initialize(target, text)
        super(nil, 'RPL_LUSERCLIENT', target, text)
      end
    end
    
    class ReplyWithCount < Reply
      attr_accessor :count
      
      def initialize(prefix, command, target, count, text)
        @count = count
        super(prefix, command, target, count, text)
      end
    end
    
    # 252 <count> :<text>
    class RplLuserop < ReplyWithCount
      def initialize(target, count, text)
        super(nil, 'RPL_LUSEROP', target, count, text)
      end
    end
    
    # 254 <count> :<text>
    class RplLuserchannels < Reply
      def initialize(target, count, text)
        super(nil, 'RPL_LUSERCHANNELS', target, count, text)
      end
    end
    
    # 255 :<text>
    class RplLuserme < Reply
      def initialize(target, text)
        super(nil, 'RPL_LUSERME', target, text)
      end
    end
    
    # 265 :<text>
    class RplLocalusers < Reply
      def initialize(target, text)
        super(nil, 'RPL_LOCALUSERS', target, text)
      end
    end
    
    # 266 :<text>
    class RplGlobalusers < Reply
      def initialize(target, text)
        super(nil, 'RPL_GLOBALUSERS', target, text)
      end
    end
    
    # 372 <target> :- <text>
    class RplMotd < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTD', target, text)
      end
    end

    # 375 <target> :- <server> Message of the day -
    class RplMotdstart < Reply
      def initialize(target, text)
        super(nil, 'RPL_MOTDSTART', target, text)
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
      attr_accessor :target, :text, :ctcp
      
      def initialize(target, text)
        @target = target
        @text, @ctcp = CTCP.parse(text)
        
        super(nil, 'NOTICE', @target, text)
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
      attr_accessor :target, :text, :ctcp
      
      def initialize(target, text)
        @target = target
        @text, @ctcp = CTCP.parse(text)
        
        super(nil, 'PRIVMSG', @target, text)
      end
    end
    
    # PRIVMSG <target>
    
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
      while line = @socket.readline
        IRC.logger.debug "<<<<< #{line.inspect}"

        message = Message.parse(line.chomp)
        
        if message.respond_to? :ctcp
          message.ctcp.each do |ctcp|
            ctcp.source = message.prefix.nickname
            yield ctcp
          end
          next if message.text.empty?
        end

        case message
        when Net::IRC::Ping
          pong message.server
        else
          yield message
        end
      end
    end

    def ctcp(target, text)
      privmsg(target, "\001#{text}\001")
    end
    
    def ctcp_version(target, client, version, environment, url = nil)
      text = "#{client} #{version} - #{environment}"
      text << " - #{url}" if url
      notice(target, CTCPVersion.new(text).to_s)
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
    
    def notice(target, text)
      Notice.new(target, text).write(@socket)
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