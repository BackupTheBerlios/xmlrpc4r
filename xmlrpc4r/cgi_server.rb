#! /usr/bin/env ruby

#
# A simple class for a CGI-based XML-RPC server
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: cgi_server.rb,v 1.1 2001/01/24 17:07:37 michael Exp $
#


=begin
= Synopsis
   require "cgi_server.rb"
   require "create.rb"
 
   s = CGI_Server.instance     
   case s.method        # name of called method
   when "michael.add"
     a,b = s.params
     puts createMethodResponse(true, a+b) 
   when "michael.div"
     a,b = s.params 
     resp = if b == 0 then
       createMethodResponse(false, {"faultCode" => 1, 
                            "faultString" => "division by zero"})
     else
       createMethodResponse(true, a/b) 
     end
     puts resp
   end 
=end

require "singleton"
require "parser"
require "create"

class CGI_Server
  include Singleton

  attr_reader :method, :params
  
  def initialize
    $stdin.binmode
    data = $stdin.read(Integer($ENV['CONTENT_LENGTH']))
    @method, @params = parseMethodCall(data) 
  end

end


