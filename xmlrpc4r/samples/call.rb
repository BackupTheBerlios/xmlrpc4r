#!/usr/bin/env ruby

require "xmlrpc/client"
 
server = XMLRPC::Client.new("localhost", "/cgi-bin/xml.cgi")

ok, params = server.call2("michael.add", 4, 5)
if ok then
  puts "4 + 5 = #{params[0]}"
else
  puts "Error:"
  puts params.faultCode 
  puts params.faultString
end

