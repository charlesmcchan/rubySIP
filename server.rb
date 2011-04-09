#!/usr/bin/env ruby
require 'sip'
require 'socket'

class SIPServer
	def initialize port
		sockfd = UDPSocket.new
		sockfd.bind('', port)
		while true
			(msg, addr) = sockfd.recvfrom MAXLEN
			response = Request.new.parse(msg).process
			sockfd.send(response, 0, addr[3], addr[1]) if response != nil
			print "\033[31m#{$usertable}\033[m"
		end
	end
end

# main
if ARGV.size != 1 then
	puts 'usage: ' + __FILE__ + ' <port>'
	exit -1
end
Signal.trap("INT") { exit -1 }
Signal.trap("TERM") { exit -1 }
SIPServer.new ARGV[0].to_i 
