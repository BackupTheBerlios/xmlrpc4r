#!/usr/bin/env ruby


require "xmlrpc/cgi_server.rb"


s = XMLRPC::CGI_Server.new
create = XMLRPC::Create.new

resp = case s.method        # name of called method
when "michael.add"
  a,b = s.params
  create.methodResponse(true, a+b) 
when "michael.div"
  a,b = s.params 
  if b == 0
    create.methodResponse(false, {"faultCode" => 1, 
                          "faultString" => "division by zero"})
  else
    create.methodResponse(true, a/b) 
  end
end

print "Content-type: text/xml\n\n"
puts resp

