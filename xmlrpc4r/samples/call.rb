require "client.rb"
 
server = XMLRPC::Server.new("localhost", 80, "/cgi-bin/xml.cgi")

ok, params = server.call("michael.add", 4, 5)
if ok then
  puts "4 + 5 = #{params[0]}"
else
  puts "Error:"
  puts params["faultCode"] 
  puts params["faultString"]
end

