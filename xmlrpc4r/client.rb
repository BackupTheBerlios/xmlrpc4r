#! /usr/bin/env ruby

#
# Implements the client-side of XML-RPC
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: client.rb,v 1.1 2001/01/24 16:24:10 michael Exp $
#


require "create"
require "parser"
require "net/http"


class Server
 
  USER_AGENT = "Ruby #{RUBY_VERSION}"

  def initialize(host, port, path)
    @path = path
    @http = Net::HTTP.new(host, port)
  end

  def call(*args)
    
    resp, data = @http.post (
                   @path, 
                   createMethodCall(*args),
                   "User-Agent"   =>  USER_AGENT,
                   "Content-Type" => "text/xml"
                 )

    @http.finish
    parseMethodResponse(data)
  end 

end


