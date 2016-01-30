require 'strscan'
require 'yaml'
require 'logger'

require 'net/irc/version'

require 'net/irc/ctcp_action'
require 'net/irc/ctcp_clientinfo'
require 'net/irc/ctcp_dcc'
require 'net/irc/ctcp_errmsg'
require 'net/irc/ctcp_finger'
require 'net/irc/ctcp_ping'
require 'net/irc/ctcp_play'
require 'net/irc/ctcp_time'
require 'net/irc/ctcp_version'

require 'net/irc/error'
require 'net/irc/err_nicknameinuse'
require 'net/irc/err_needreggednick'
require 'net/irc/join'
require 'net/irc/mode'
require 'net/irc/nick'
require 'net/irc/notice'
require 'net/irc/part'
require 'net/irc/pass'
require 'net/irc/ping'
require 'net/irc/pong'
require 'net/irc/privmsg'
require 'net/irc/quit'
require 'net/irc/rpl_created'
require 'net/irc/rpl_endofmotd'
require 'net/irc/rpl_endofnames'
require 'net/irc/rpl_globalusers'
require 'net/irc/rpl_isupport'
require 'net/irc/rpl_localusers'
require 'net/irc/rpl_luserchannels'
require 'net/irc/rpl_luserclient'
require 'net/irc/rpl_luserme'
require 'net/irc/rpl_luserop'
require 'net/irc/rpl_luserunknown'
require 'net/irc/rpl_loggedin'
require 'net/irc/rpl_loggedout'
require 'net/irc/rpl_motd'
require 'net/irc/rpl_motdstart'
require 'net/irc/rpl_myinfo'
require 'net/irc/rpl_namreply'
require 'net/irc/rpl_statsconn'
require 'net/irc/rpl_topic'
require 'net/irc/rpl_topicwhotime'
require 'net/irc/rpl_welcome'
require 'net/irc/rpl_yourhost'
require 'net/irc/user'

module Net
  class IRC
    include Enumerable

    PORT_DEFAULT = 6667

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new('net-irc.log')
      end

      def start(user, password, realname, address, port = nil, &block)
        new(address, port).start(user, password, realname, &block)
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

    def start(user, password, realname, nickname = nil)
      raise IOError, 'IRC session already started' if started?

      if block_given?
        begin
          do_start(user, password, realname, nickname)
          return yield(self)
        ensure
          do_finish
        end
      else
        do_start(user, password, realname, nickname)
        return self
      end
    end

    def finish
      raise IOError, 'IRC session not yet started' unless started?
    end

    def each
      while line = @socket.readline
        IRC.logger.debug "<<<<< #{line.inspect}"

        message = Message.parse(line.chomp)

        if message.respond_to? :ctcp
          message.ctcp.each do |ctcp|
            ctcp.source = message.prefix.nickname
            ctcp.target = message.target

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
    rescue IOError
      raise if started?
    end

    def ctcp(target, text)
      privmsg(target, "\001#{text}\001")
    end

    def ctcp_version(target, *parameters)
      notice(target, CTCPVersion.new(*parameters).to_s)
    end

    def ctcp_ping(target, arg = nil)
      notice(target, CTCPPing.new(arg).to_s)
    end

    def ctcp_time(target, time = nil)
      time ||= Time.now
      differential = '%.2d%.2d' % (time.utc_offset / 60).divmod(60)
      notice(target, CTCPTime.new(time.strftime("%a, %d %b %Y %H:%M #{differential}")).to_s)
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

    def pass(password)
      Pass.new(password).write(@socket)
    end

    def pong(server, target = nil)
      Pong.new(server, target).write(@socket)
    end

    def privmsg(target, text)
      Privmsg.new(target, text).write(@socket)
    end

    def quit(text = nil)
      Quit.new(text).write(@socket)
    end

    def user(user, realname, mode = nil)
      User.new(user, mode || User::MODE_DEFAULT, realname).write(@socket)
    end

    private

    def do_start(user, password, realname, nickname = nil)
      @socket = InternetMessageIO.new(TCPSocket.open(@address, @port))
      pass(password) unless password.nil? || password.empty?
      nick(user)
      user(user, realname)
      @started = true
    ensure
      do_finish unless started?
    end

    def do_finish
      quit if started?
    ensure
      @started = false
      @socket.close if @socket && ! @socket.closed?
      @socket = nil
    end
  end
end
