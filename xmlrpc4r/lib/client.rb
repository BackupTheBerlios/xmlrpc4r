#! /usr/bin/env ruby

#
# Implements the client-side of XML-RPC
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: client.rb,v 1.2 2001/01/25 22:41:53 michael Exp $
#


=begin
= Synopsis
   require "xmlrpc/client.rb"
 
   server = XMLRPC::Server.new("www.ruby-lang.org", 80, "/RPC2")
   ok, params = server.call("michael.add", 4, 5)
   if ok then
     puts "4 + 5 = #{params[0]}"
   else
     puts "Error:"
     puts params["faultCode"] 
     puts params["faultString"]
   end
=end



require "xmlrpc/parser.rb"
require "xmlrpc/create.rb"
require "net/http"

module XMLRPC

class Server
 
  USER_AGENT = "Ruby #{RUBY_VERSION}"

  def initialize(host, port, path)
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

end # module

