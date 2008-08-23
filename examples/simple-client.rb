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
  irc.each do |event|
    case event
    when Net::IRC::Join
      puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} joined #{highlight(event.channels.first, BOLD, fg(GREEN))}."
    when Net::IRC::Part
      if event.text && ! event.text.empty?
        puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(event.channels.first, BOLD, fg(GREEN))} (#{event.text})."
      else
        puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} has left #{highlight(event.channels.first, BOLD, fg(GREEN))}."
      end
    when Net::IRC::Quit
      if event.text && ! event.text.empty?
        puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} has quit (#{event.text})."
      else
        puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} has quit."
      end
    when Net::IRC::Notice
      puts highlight(event.text, fg(BLUE))
    when Net::IRC::Privmsg
      puts "#{highlight(event.prefix.nickname, BOLD, fg(YELLOW))} #{highlight(event.channels.first, BOLD, fg(GREEN))}: #{highlight(event.text, BOLD)}"
    when Net::IRC::ErrNicknameinuse
      irc.nick event.nickname.sub(/\d*$/) { |n| n.to_i + 1 }
    when Net::IRC::Error
      puts highlight("Unhandled ERROR: #{event.class}", BOLD, fg(RED))
    when Net::IRC::RplWelcome, Net::IRC::RplYourhost, Net::IRC::RplCreated
      puts event.text
    when Net::IRC::RplMyinfo
    when Net::IRC::RplMotdstart
      puts ""
    when Net::IRC::RplMotd
      puts event.text.sub(/^- /,'')
    when Net::IRC::RplEndofmotd
      puts ""
      irc.join '#rubyonrails'
    when Net::IRC::Reply
      puts highlight("Unhandled REPLY: #{event.class}", BOLD, fg(RED))
    when Net::IRC::Ping
      irc.pong event.server
    when Net::IRC::Message
      puts highlight("Unhandled #{event.command}", BOLD, fg(RED))
    else
      puts highlight("Unhandled #{event.class}", BOLD, fg(RED))
    end
  end
end
