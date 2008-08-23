#!/usr/bin/ruby

$:.push(File.join(File.dirname(__FILE__),'../lib'))

require 'net/irc'

# require "socket"
# 
# # Don't allow use of "tainted" data by potentially dangerous operations
# $SAFE=1
# 
# # The irc class, which talks to the server and holds the main event loop
# class IRC
#     def initialize(server, port, nick, channel)
#         @server = server
#         @port = port
#         @nick = nick
#         @channel = channel
#     end
#     def send(s)
#         # Send a message to the irc server and print it to the screen
#         puts "--> #{s}"
#         @irc.send "#{s}\n", 0 
#     end
#     def connect()
#         # Connect to the IRC server
#         @irc = TCPSocket.open(@server, @port)
#         send "USER blah blah blah :blah blah"
#         send "NICK #{@nick}"
#         send "JOIN #{@channel}"
#     end
#     def evaluate(s)
#         # Make sure we have a valid expression (for security reasons), and
#         # evaluate it if we do, otherwise return an error message
#         if s =~ /^[-+*\/\d\s\eE.()]*$/ then
#             begin
#                 s.untaint
#                 return eval(s).to_s
#             rescue Exception => detail
#                 puts detail.message()
#             end
#         end
#         return "Error"
#     end
#     def handle_server_input(s)
#         # This isn't at all efficient, but it shows what we can do with Ruby
#         # (Dave Thomas calls this construct "a multiway if on steroids")
#         case s.strip
#             when /^PING :(.+)$/i
#                 puts "[ Server ping ]"
#                 send "PONG :#{$1}"
#             when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
#                 puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
#                 send "NOTICE #{$1} :\001PING #{$4}\001"
#             when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
#                 puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
#                 send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
#             when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
#                 puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
#                 send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
#             else
#                 puts s
#         end
#     end
#     def main_loop()
#         # Just keep on truckin' until we disconnect
#         while true
#             ready = select([@irc, $stdin], nil, nil, nil)
#             next if !ready
#             for s in ready[0]
#                 if s == $stdin then
#                     return if $stdin.eof
#                     s = $stdin.gets
#                     send s
#                 elsif s == @irc then
#                     return if @irc.eof
#                     s = @irc.gets
#                     handle_server_input(s)
#                 end
#             end
#         end
#     end
# end
# 
# # The main program
# # If we get an exception, then print it out and keep going (we do NOT want
# # to disconnect unexpectedly!)
# irc = IRC.new('efnet.skynet.be', 6667, 'Alt-255', '#cout')
# irc.connect()
# begin
#     irc.main_loop()
# rescue Interrupt
# rescue Exception => detail
#     puts detail.message()
#     print detail.backtrace.join("\n")
#     retry
# end

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
