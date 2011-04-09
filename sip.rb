#!/usr/bin/env ruby
# global definition
MAXLEN = 1024		# max length of SIP message
# global variable
$usertable = Hash.new

class Request
	attr_reader :header, :body, :type, :version
	
	def initialize
		@header = Hash.new
	end

	def parse msg
		(header, body) = msg.split /\r\n\r\n/
		puts "\033[32m#{header}\033[m"
		puts "\033[36m#{body}\033[m"
		# parse header and put into hash
		header.each {|line|
			case line.chomp!
			when /^REGISTER.+/ then
				@type = 'REGISTER'
				@version = line.split(' ')[2]
			when /^INVITE.+/ then
				@type = 'INVITE'
				@version = line.split(' ')[2]
			when /^ACK.+/ then
				@type = 'ACK'
				@version = line.split(' ')[2]
			else
				map = line.split(':', 2)
				@header[map[0]] = map[1]
			end
		}
		# parse body
		@body = body
		return self
	end

	def process
		case @type
		when 'REGISTER' then response = register
		when 'INVITE' then response = invite	
		when 'ACK' then response = ack
		end	
		# return response
		print "\033[33m#{response}\033[m"
		return response
	end

	def register
		# generate response
		response = "#{@version} 200 OK\r\n"
		@header.each {|map|
			next if map[0]=~/Max-Forwards/
			response += "#{map[0]}:#{map[1]}\r\n"
		}
		response += "\r\n"
		# add to->contact mapping to usertable
		#TODO
		#re-register
		#un-register
		$usertable[@header['From']] = @header['Contact']
		return response
	end
	
	def invite
		# generate response
		response = "#{@version} 302 Moved Temporarily\r\n"
		@header.each {|map|
			next if map[0]=~/Content-.+/ || map[0]=~/Contact/ || map[0]=~/Max-Forwards/
			response += "#{map[0]}:#{map[1]}\r\n"
		}
		# find contact data in usertable
		response += "Contact: #{$usertable[@header['To']]}"
		response += "\r\n"
		return response	
	end

	def ack
		# no response to ACK
		return nil
	end
end
