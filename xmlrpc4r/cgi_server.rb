#! /usr/bin/env ruby

#
# A simple class for a CGI-based XML-RPC server
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: cgi_server.rb,v 1.3 2001/01/24 19:47:22 michael Exp $
#


=begin
= Synopsis
   require "cgi_server.rb"
 
   s = CGI_Server.new     
   resp = case s.method        # name of called method
   when "michael.add"
     a,b = s.params
     createMethodResponse(true, a+b) 
   when "michael.div"
     a,b = s.params 
     if b == 0 then
       createMethodResponse(false, {"faultCode" => 1, 
                            "faultString" => "division by zero"})
     else
       createMethodResponse(true, a/b) 
     end
   end 

   puts "Content-type: text/xml\n"
   puts resp
=end

require "parser.rb"
require "create.rb"

class CGI_Server
  @@init = false

  attr_reader :method, :params
  
  def initialize
    if not @@init  
      $stdin.binmode
      data = $stdin.read(Integer(ENV['CONTENT_LENGTH']))
      @method, @params = parseMethodCall(data) 
      @@init = true
    end
  end

end


