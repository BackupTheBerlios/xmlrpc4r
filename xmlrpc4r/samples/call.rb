#!/usr/bin/env ruby

require "xmlrpc/client"
 
server = XMLRPC::Client.new("localhost", "/cgi-bin/xml.cgi", 8070)
#server = XMLRPC::Client.new("localhost", "/cgi-bin/xml.fcgi", 80)

ok, param = server.call2("michael.add", 4, 5)
if ok then
  puts "4 + 5 = #{param}"
else
  puts "Error:"
  puts param.faultCode 
  puts param.faultString
end

p server.call("system.listMethods")
