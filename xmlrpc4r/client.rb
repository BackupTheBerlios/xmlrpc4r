#! /usr/bin/env ruby

#
# Implements the client-side of XML-RPC
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: client.rb,v 1.3 2001/01/24 18:01:36 michael Exp $
#


=begin
= Synopsis
   require "client.rb"
 
   server = Server.new("www.ruby-lang.org", 80, "/RPC2")
   ok, params = server.call("michael.add", 4, 5)
   if ok then
     puts "4 + 5 = #{params[0]}"
   else
     puts "Error:"
     puts params["faultCode"] 
     puts params["faultString"]
   end
=end



require "parser.rb"
require "create.rb"
require "net/http"


class Server
 
  USER_AGENT = "Ruby #{RUBY_VERSION}"

  def initialize(host, port, path)
    @path = path
    @http = Net::HTTP.new(host, port)
  end

  def call(method, *args)
    
    resp, data = @http.post (
                   @path, 
                   createMethodCall(method, *args),
                   "User-Agent"   =>  USER_AGENT,
                   "Content-Type" => "text/xml"
                 )

    @http.finish
    parseMethodResponse(data)
  end 

end

