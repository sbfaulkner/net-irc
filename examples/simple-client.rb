#!/usr/bin/ruby

$:.push(File.join(File.dirname(__FILE__),'../lib'))

require 'net/irc'

module Ansi
  RESET = 0
  BOLD = 1
  DIM = 2
  UNDERSCORE = 4
  BLINK = 5
  REVERSE = 7
  HIDDEN = 8
  
  BLACK = 0
  RED = 1
  GREEN = 2
  YELLOW = 3
  BLUE = 4
  MAGENTA = 5
  CYAN = 6
  WHITE = 7
  
  def esc(*attrs)
    "\033[#{attrs.join(';')}m"
  end
  
  def fg(colour)
    30 + colour
  end
  
  def bg(colour)
    40 + colour
  end
  
  def highlight(text, *attrs)
    "#{esc(*attrs)}#{text}#{esc(RESET)}"
  end
end

include Ansi

Net::IRC.logger.level = Logger::DEBUG
Net::IRC.logger.datetime_format = "%Y/%m/%d %H:%M:%S"

Thread.abort_on_exception = true

Net::IRC.start 'unwwwired', 'S. Brent Faulkner', 'irc.freenode.net' do |irc|
  Thread.new do
    irc.each do |message|
      case message
      # TODO: required = VERSION, PING, CLIENTINFO, ACTION
      # TODO: handle internally... probably true for most CTCP requests
      when Net::IRC::CTCPVersion
        irc.ctcp_version(message.source, "net-irc simple-client", Net::IRC::VERSION, PLATFORM, "http://www.github.com/sbfaulkner/net-irc")
    
      when Net::IRC::CTCPAction
        puts "#{highlight(message.source, BOLD, fg(YELLOW))} #{highlight(message.target, BOLD, fg(GREEN))}: #{highlight(message.text, BOLD)}"

      when Net::IRC::CTCPPing
        irc.ctcp_ping(message.source, message.arg)

      when Net::IRC::CTCPTime
        irc.ctcp_time(message.source)
        
      when Net::IRC::CTCP
        puts highlight("Unhandled CTCP REQUEST: #{message.class} (#{message.keyword})", BOLD, fg(RED))

      when Net::IRC::Join
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} joined #{highlight(message.channels.first, BOLD, fg(GREEN))}."
      
      when Net::IRC::Part
        if message.text && ! message.text.empty?
          puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(message.channels.first, BOLD, fg(GREEN))} (#{message.text})."
        else
          puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(message.channels.first, BOLD, fg(GREEN))}."
        end
      
      when Net::IRC::Mode
        # TODO: handle internally
        puts highlight("#{message.channel} mode changed #{message.modes}", fg(BLUE))
        
      when Net::IRC::Quit
        if message.text && ! message.text.empty?
          puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has quit (#{message.text})."
        else
          puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has quit."
        end
      
      when Net::IRC::Notice
        puts highlight(message.text, fg(CYAN))
      
      when Net::IRC::Privmsg
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} #{highlight(message.target, BOLD, fg(GREEN))}: #{highlight(message.text, BOLD)}"
      
      when Net::IRC::Nick
        puts "#{highlight(message.prefix.nickname, BOLD)} is now #{highlight(message.nickname, BOLD, fg(YELLOW))}"
        
      when Net::IRC::ErrNicknameinuse
        irc.nick message.nickname.sub(/\d*$/) { |n| n.to_i + 1 }
      
      when Net::IRC::Error
        puts highlight("Unhandled ERROR: #{message.class} (#{message.command})", BOLD, fg(RED))
      
      when Net::IRC::RplWelcome, Net::IRC::RplYourhost, Net::IRC::RplCreated
        puts message.text
    
      when Net::IRC::RplLuserclient, Net::IRC::RplLuserme, Net::IRC::RplLocalusers, Net::IRC::RplGlobalusers, Net::IRC::RplStatsconn
        puts highlight(message.text, fg(BLUE))

      when Net::IRC::RplLuserop, Net::IRC::RplLuserchannels
        puts highlight("#{message.count} #{message.text}", fg(BLUE))
      
      when Net::IRC::RplIsupport
        # TODO: handle internally... parse into capabilities collection
      
      when Net::IRC::RplMyinfo
      when Net::IRC::RplMotdstart

      when Net::IRC::RplTopic
        # TODO: handle internally
        puts "#{highlight(message.channel, BOLD, fg(GREEN))}: #{message.text}"

      when Net::IRC::RplTopicwhotime
        # TODO: handle internally
        puts "#{highlight(message.channel, BOLD, fg(GREEN))}: #{message.nickname} #{message.time.strftime("%Y/%m/%d %H:%M:%S")}"

      when Net::IRC::RplNamreply
        # TODO: handle internally
        puts "#{highlight(message.channel, BOLD, fg(GREEN))}: #{message.names.join(', ')}"
      
      when Net::IRC::RplEndofnames
        # TODO: handle internally

      when Net::IRC::RplMotd
        puts message.text.sub(/^- /,'')
      
      when Net::IRC::RplEndofmotd
        puts ""
    
      when Net::IRC::Reply
        puts highlight("Unhandled REPLY: #{message.class} (#{message.command})", BOLD, fg(RED))
      
      when Net::IRC::Message
        puts highlight("Unhandled MESSAGE: #{message.class} (#{message.command})", BOLD, fg(RED))
      
      else
        raise IOError, "unknown class #{message.class}"
      
      end
    end
  end

  while line = STDIN.gets
    scanner = StringScanner.new(line.chomp)
    if command = scanner.scan(/\/([[:alpha:]]+)\s*/) && scanner[1]
      case command.upcase
      when 'JOIN'
        # TODO: validate arguments... support for password... etc.
        irc.join scanner.rest
        
      when 'PART'
        # TODO: validate arguments... support for password... etc.
        irc.part scanner.rest
        
      when 'QUIT'
        break
      else
        puts highlight("Unknown COMMAND: #{command}", BOLD, fg(RED))
      end
    else
      # TODO: send privmsg to channel
    end
  end
end
