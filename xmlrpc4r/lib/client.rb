#
# Implements the client-side of XML-RPC
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: client.rb,v 1.6 2001/01/27 13:08:37 michael Exp $
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

= Description
Class (({XMLRPC::Client})) provides method calls to an XML-RPC server.

= Class Methods
--- XMLRPC::Client.new( host, path="/RPC2", port=80 )
    Creates an object which represents the remote XML-RPC server on the 
    given host ((|host|)). If the server is CGI-based, ((|path|)) is the
    path to the CGI-script, which will be called, otherwise (in the
    case of a standalone server) ((|path|)) should be (({"/RPC2"})).
    Finally ((|port|)) is the port on which the XML-RPC server listens.

= Instance Methods
--- XMLRPC::Client#call( method, *args )
    Invokes the method named ((|method|)) with the parameters given by ((|args|)) 
    on the XML-RPC server.
    The parameter ((|method|)) is converted into a (({String})) and should be a valid 
    XML-RPC method-name.  
    The variable number of parameters given by ((|args|)) must be at least one parameter, 
    because XML-RPC do not allow calls without paramter.
    Each parameter of ((|args|)) must be of one of the following types,
    where (({Hash})) and (({Array})) can contain any of these listed types:
    * (({Fixnum}))
    * (({TrueClass})), (({FalseClass})) ((({true})), (({false})))
    * (({String}))
    * (({Float}))
    * (({Hash}))
    * (({Array}))
    * (({Date})), (({Time}))
    * (({XMLRPC::Base64})) 
    
    The method returns an array of two values. The first value indicates if the second value 
    is a return-value ((({true}))) or a fault-structure ((({false}))).
    * A return-value is an array containing all the return-values from the RPC. The types are the
      same as above, only that a XML-RPC (('dateTime.iso8601')) type is, when possible, returned as
      a Ruby (({Time})) object and only if the range disallows as a (({Date})). 
    * A fault-structure is a (({Hash})) object containing a key (({"faultCode"})) which value is a (({Fixnum})) 
      and a key (({"faultString"})) which value is a (({String})).
= History
    $Id: client.rb,v 1.6 2001/01/27 13:08:37 michael Exp $
=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "net/http"

module XMLRPC

class Client
 
  USER_AGENT = "XMLRPC::Client (Ruby #{RUBY_VERSION})"

  def initialize(host, path="/RPC2", port=80)
    @path = path
    @http = Net::HTTP.new(host, port) end

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

