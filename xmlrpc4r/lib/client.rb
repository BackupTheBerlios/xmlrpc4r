=begin

= XMLRPC::Client
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

= Synopsis
    require "xmlrpc/client"

    server = XMLRPC::Client.new("www.ruby-lang.org", "/RPC2", 80)
    begin
      param = server.call("michael.add", 4, 5)
      puts "4 + 5 = #{param}"
    rescue XMLRPC::FaultException => e
      puts "Error:"
      puts e.faultCode
      puts e.faultString
    end
or
    require "xmlrpc/client"
  
    server = XMLRPC::Client.new("www.ruby-lang.org", "/RPC2", 80)
    ok, param = server.call("michael.add", 4, 5)
    if ok then
      puts "4 + 5 = #{param}"
    else
      puts "Error:"
      puts params["faultCode"] 
      puts params["faultString"]
    end

= Description
Class (({XMLRPC::Client})) provides remote procedure calls to a XML-RPC server.
After setting the connection-parameters with ((<XMLRPC::Client.new>)) which
creates a new (({XMLRPC::Client})) instance, you can execute a remote procedure 
by sending the ((<call|XMLRPC::Client#call>)) or ((<call2|XMLRPC::Client#call2>))
message to this new instance, giving parameters that indicate which method to 
call on the remote-side and of course the parameters for the remote procedure.

= Class Methods
--- XMLRPC::Client.new( host, path="/RPC2", port=80 )
    Creates an object which represents the remote XML-RPC server on the 
    given host ((|host|)). If the server is CGI-based, ((|path|)) is the
    path to the CGI-script, which will be called, otherwise (in the
    case of a standalone server) ((|path|)) should be (({"/RPC2"})).
    Finally ((|port|)) is the port on which the XML-RPC server listens.

= Instance Methods
--- XMLRPC::Client#call( method, *args )
    Invokes the method named ((|method|)) with the parameters given by 
    ((|args|)) on the XML-RPC server.
    The parameter ((|method|)) is converted into a (({String})) and should 
    be a valid XML-RPC method-name.  
    The variable number of parameters given by ((|args|)) must be at least 
    one parameter, because XML-RPC do not allow calls without paramter.
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
    
    The method returns the return-value from the RPC ((-stands for Remote Procedure Call-)). 
    The type of the return-value is one of the above shown,
    only that a XML-RPC (('dateTime.iso8601')) type is, when possible, 
    returned as a Ruby (({Time})) object and only if the range disallows as 
    a (({Date})). 
    If the remote procedure returned a fault-structure, then a 
    (({XMLRPC::FaultException})) exception is raised, which has two accessor-methods
    (({XMLRPC::FaultException#faultCode})) and 
    (({XMLRPC::FaultException#faultString})) of type (({Integer})) and (({String})).

--- XMLRPC::Client#call2( method, *args )
    The difference between this method and ((<call|XMLRPC::Client#call>)) is, that
    this method do ((*not*)) raise a (({XMLRPC::FaultException})) exception.
    The method returns an array of two values. The first value indicates if 
    the second value is a return-value ((({true}))) or an object of type
    (({XMLRPC::FaultException})). 
    Both are explained in ((<call|XMLRPC::Client#call>)).

= History
    $Id: client.rb,v 1.11 2001/01/27 19:57:35 michael Exp $
=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "net/http"

module XMLRPC

class Client
 
  USER_AGENT = "XMLRPC::Client (Ruby #{RUBY_VERSION})"

  def initialize(host, path="/RPC2", port=80)
    @path = path
    @http = Net::HTTP.new(host, port)
  end

  def call(method, *args)
    ok, params = call2(method, *args) 
    return params if ok
    raise params
  end 
 
  def call2(method, *args)
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

