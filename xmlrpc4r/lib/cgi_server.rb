#
# A simple class for a CGI-based XML-RPC server
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: cgi_server.rb,v 1.4 2001/01/27 17:14:04 michael Exp $
#


=begin
= Synopsis
   require "xmlrpc/cgi_server"
 
   create = XMLRPC::Create.new
   s = XMLRPC::CGIServer.new     

   resp = case s.method        # name of called method
   when "michael.add"
     a,b = s.params
     create.methodResponse(true, a+b) 
   when "michael.div"
     a,b = s.params 
     if b == 0 then
       create.methodResponse(false, {"faultCode" => 1, 
                             "faultString" => "division by zero"})
     else
       create.methodResponse(true, a/b) 
     end
   end 

   puts "Content-type: text/xml\n"
   puts resp
=end

require "xmlrpc/parser"
require "xmlrpc/create"

module XMLRPC

class CGIServer
  @@obj = nil

  attr_reader :method, :params
  
  def CGIServer.new
    @@obj = super if @@obj.nil?
    @@obj
  end

  def initialize
    $stdin.binmode
    data = $stdin.read(ENV['CONTENT_LENGTH'].to_i)
    parser = Parser.new
    @method, @params = parser.parseMethodCall(data) 
  end

end

end # module XMLRPC

