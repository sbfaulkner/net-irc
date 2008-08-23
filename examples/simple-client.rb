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

Net::IRC.start 'unwwwired', 'S. Brent Faulkner', 'irc.freenode.net' do |irc|
  irc.each do |message|
    case message
    when Net::IRC::Join
      puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} joined #{highlight(message.channels.first, BOLD, fg(GREEN))}."
      
    when Net::IRC::Part
      if message.text && ! message.text.empty?
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(message.channels.first, BOLD, fg(GREEN))} (#{message.text})."
      else
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(message.channels.first, BOLD, fg(GREEN))}."
      end
      
    when Net::IRC::Quit
      if message.text && ! message.text.empty?
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has quit (#{message.text})."
      else
        puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} has quit."
      end
      
    when Net::IRC::Notice
      if message.ctcp?
        message.ctcp.each do |req|
          case req
          when ''
          else
            puts highlight("Unhandled CTCP REQUEST: #{req}", BOLD, fg(RED))
          end
        end
      end
      puts highlight(message.text, fg(BLUE)) unless message.text.empty?
      
    when Net::IRC::Privmsg
      if message.ctcp?
        message.ctcp.each do |req|
          case req
          when ''
          else
            puts highlight("Unhandled CTCP REQUEST: #{req}", BOLD, fg(RED))
          end
        end
      end
      puts "#{highlight(message.prefix.nickname, BOLD, fg(YELLOW))} #{highlight(message.target, BOLD, fg(GREEN))}: #{highlight(message.text, BOLD)}" unless message.text.empty?
      
    when Net::IRC::ErrNicknameinuse
      irc.nick message.nickname.sub(/\d*$/) { |n| n.to_i + 1 }
      
    when Net::IRC::Error
      puts highlight("Unhandled ERROR: #{message.class} (#{message.command})", BOLD, fg(RED))
      
    when Net::IRC::RplWelcome, Net::IRC::RplYourhost, Net::IRC::RplCreated
      puts message.text
      
    when Net::IRC::RplMyinfo
    when Net::IRC::RplIsupport
    when Net::IRC::RplMotdstart
      puts ""
      
    when Net::IRC::RplMotd
      puts message.text.sub(/^- /,'')
      
    when Net::IRC::RplEndofmotd
      puts ""
      irc.join '#rubyonrails'
      
    when Net::IRC::Reply
      puts highlight("Unhandled REPLY: #{message.class} (#{message.command})", BOLD, fg(RED))
      
    when Net::IRC::Ping
      irc.pong message.server
      
    when Net::IRC::Message
      puts highlight("Unhandled MESSAGE: #{message.class} (#{message.command})", BOLD, fg(RED))
      
    else
      raise IOError, "unknown class #{message.class}"
      
    end
  end
end
