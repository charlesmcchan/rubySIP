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
			when /^REGISTER.+/ then	(@type, @version) = 'REGISTER', line.split(' ')[2]
			when /^INVITE.+/ then	(@type, @version) = 'INVITE', line.split(' ')[2]
			when /^ACK.+/ then (@type, @version) = 'ACK', line.split(' ')[2]
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
		# dispatch request
		response = case @type
		when 'REGISTER' then register
		when 'INVITE' then invite	
		when 'ACK' then ack
		end	
		# return response
		print "\033[33m#{response}\033[m"
		return response
	end

	def register
		# generate response
		response = "#{@version} 200 OK\r\n"
		@header.each {|map|
			next if map[0]=='Max-Forwards'
			response += "#{map[0]}:#{map[1]}\r\n"
		}
		response += "\r\n"
		# add to->contact mapping to usertable
		# TODO: register timeout
		# un-register cannot be done by CCL SIP UA, omitted
		# re-register is done trivially by the property of Hash
		$usertable[@header['To']] = @header['Contact']
		return response
	end
	
	def invite
		# generate response
		response = "#{@version} 302 Moved Temporarily\r\n"
		@header.each {|map|
			next if map[0]=~/Content-.+/ || map[0]=='Contact' || map[0]=='Max-Forwards'
			response += "#{map[0]}:#{map[1]}\r\n"
		}
		# find contact data in usertable
		response += "Contact: #{$usertable[@header['To']]}\r\n"
		response += "\r\n"
		return response	
	end

	def ack
		# no response to ACK
		return nil
	end
end
