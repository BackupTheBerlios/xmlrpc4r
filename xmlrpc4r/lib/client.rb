#
# Implements the client-side of XML-RPC
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: client.rb,v 1.5 2001/01/27 11:34:16 michael Exp $
#


=begin
= Synopsis
   require "xmlrpc/client"
 
   server = XMLRPC::Client.new("www.ruby-lang.org", "/RPC2", 80)
   ok, params = server.call("michael.add", 4, 5)
   if ok then
     puts "4 + 5 = #{params[0]}"
   else
     puts "Error:"
     puts params["faultCode"] 
     puts params["faultString"]
   end
=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "net/http"

module XMLRPC

class Client
 
  USER_AGENT = "XMLRPC::Client (Ruby #{RUBY_VERSION})"

  def initialize(host, path = "/RPC2", port = 80)
    @path = path
    @http = Net::HTTP.new(host, port)
  end

  def call(method, *args)
    
    create = Create.new
    parser = Parser.new

    resp, data = @http.post (
                   @path, 
                   create.methodCall(method, *args),
                   "User-Agent"   =>  USER_AGENT,
                   "Content-Type" => "text/xml"
                 )

    @http.finish
    parser.parseMethodResponse(data)
  end 

end

end # module XMLRPC

