=begin
= xmlrpc/client.rb
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

= Classes
* ((<XMLRPC::Client>))
* ((<XMLRPC::Client::Proxy>))


= XMLRPC::Client
== Synopsis
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
    ok, param = server.call2("michael.add", 4, 5)
    if ok then
      puts "4 + 5 = #{param}"
    else
      puts "Error:"
      puts param.faultCode
      puts param.faultString
    end

== Description
Class (({XMLRPC::Client})) provides remote procedure calls to a XML-RPC server.
After setting the connection-parameters with ((<XMLRPC::Client.new>)) which
creates a new (({XMLRPC::Client})) instance, you can execute a remote procedure 
by sending the ((<call|XMLRPC::Client#call>)) or ((<call2|XMLRPC::Client#call2>))
message to this new instance. The given parameters indicate which method to 
call on the remote-side and of course the parameters for the remote procedure.

== Class Methods
--- XMLRPC::Client.new( host, path="/RPC2", port=80, proxy_addr=nil, proxy_port=nil )
    Creates an object which represents the remote XML-RPC server on the 
    given host ((|host|)). If the server is CGI-based, ((|path|)) is the
    path to the CGI-script, which will be called, otherwise (in the
    case of a standalone server) ((|path|)) should be (({"/RPC2"})).
    ((|port|)) is the port on which the XML-RPC server listens.
    If ((|proxy_addr|)) is given, then a proxy server listening at
    ((|proxy_addr|)) is used. ((|proxy_port|)) is the port of the
    proxy server.

== Instance Methods
--- XMLRPC::Client#call( method, *args )
    Invokes the method named ((|method|)) with the parameters given by 
    ((|args|)) on the XML-RPC server.
    The parameter ((|method|)) is converted into a (({String})) and should 
    be a valid XML-RPC method-name.  
    Each parameter of ((|args|)) must be of one of the following types,
    where (({Hash})), (({Struct})) and (({Array})) can contain any of these listed ((:types:)):
    * (({Fixnum})), (({Bignum}))
    * (({TrueClass})), (({FalseClass})) ((({true})), (({false})))
    * (({String})), (({Symbol}))
    * (({Float}))
    * (({Hash})), (({Struct}))
    * (({Array}))
    * (({Date})), (({Time})), (({XMLRPC::DateTime}))
    * (({XMLRPC::Base64})) 
    
    The method returns the return-value from the RPC 
    ((-stands for Remote Procedure Call-)). 
    The type of the return-value is one of the above shown,
    only that a (({Bignum})) is only allowed when it fits in 32-bit and
    that a XML-RPC (('dateTime.iso8601')) type is always returned as
    a ((<(({XMLRPC::DateTime}))|URL:datetime.html>)) object and 
    a (({Struct})) is never returned, only a (({Hash})), the same for a (({Symbol})), where
    always a (({String})) is returned. 
    A (({XMLRPC::Base64})) is returned as a (({String})) from xmlrpc4r version 1.6.1 on.
    
    If the remote procedure returned a fault-structure, then a 
    (({XMLRPC::FaultException})) exception is raised, which has two accessor-methods
    (({faultCode})) and (({faultString})) of type (({Integer})) and (({String})).

--- XMLRPC::Client#call2( method, *args )
    The difference between this method and ((<call|XMLRPC::Client#call>)) is, that
    this method do ((*not*)) raise a (({XMLRPC::FaultException})) exception.
    The method returns an array of two values. The first value indicates if 
    the second value is a return-value ((({true}))) or an object of type
    (({XMLRPC::FaultException})). 
    Both are explained in ((<call|XMLRPC::Client#call>)).

--- XMLRPC::Client#multicall( array_of_methods )
    You can use this method to execute several methods on a XMLRPC server which supports
    the multi-call extension.
    Example:

      s.multicall(
        ['michael.add', 3, 4],
        ['michael.sub', 4, 5]
      )
      # => [[7], [-1]]

--- XMLRPC::Client#multicall2( array_of_methods )
    Same as ((<XMLRPC::Client#multicall>)), but returns like ((<XMLRPC::Client#call2>)) two parameters 
    instead of raising an (({XMLRPC::FaultException})).

--- XMLRPC::Client#proxy( prefix, *args )
    Returns an object of class (({XMLRPC::Client::Proxy})), initialized with
    ((|prefix|)) and ((|args|)). A proxy object returned by this method behaves
    like ((<XMLRPC::Client#call>)), i.e. a call on that object will raise a
    (({XMLRPC::FaultException})) when a fault-structure is returned by that call. 

--- XMLRPC::Client#proxy2( prefix, *args )
    Almost the same like ((<XMLRPC::Client#proxy>)) only that a call on the returned
    (({XMLRPC::Client::Proxy})) object behaves like ((<XMLRPC::Client#call2>)), i.e.
    a call on that object will return two parameters. 


--- XMLRPC::Client#set_writer( writer )
    Sets the XML writer to use for generating XML output.
    Should be an instance of a class from module (({XMLRPC::XMLWriter})).
    If this method is not called, then (({XMLRPC::XMLWriter::DEFAULT_WRITER})) is used. 

--- XMLRPC::Client#set_parser( parser )
    Sets the XML parser to use for parsing XML documents.
    Should be an instance of a class from module (({XMLRPC::XMLParser})).
    If this method is not called, then (({XMLRPC::XMLParser::DEFAULT_WRITER})) is used.


= XMLRPC::Client::Proxy
== Synopsis
    require "xmlrpc/client"

    server = XMLRPC::Client.new("www.ruby-lang.org", "/RPC2", 80)

    michael  = server.proxy("michael")
    michael2 = server.proxy("michael", 4)

    # both calls should return the same value '9'.
    p michael.add(4,5)
    p michael2.add(5)

== Description
Class (({XMLRPC::Client::Proxy})) makes XML-RPC calls look nicer!
You can call any method onto objects of that class - the object handles 
(({method_missing})) and will forward the method call to a XML-RPC server.
Don't use this class directly, but use instead method ((<XMLRPC::Client#proxy>)) or
((<XMLRPC::Client#proxy2>)).

== Class Methods
--- XMLRPC::Client::Proxy.new( server, prefix, args=[], call=true, delim="." ) 
    Creates an object which provides (({method_missing})).
    ((|server|)) must be of type (({XMLRPC::Client})), which is the XML-RPC server to be used
    for a XML-RPC call. ((|prefix|)) and ((|delim|)) will be prepended to the methodname
    called onto this object. If ((|call|)) is (({true})) then ((<XMLRPC::Client#call>)) is used,
    otherwise ((<XMLRPC::Client#call2>)). ((|args|)) are arguments which are automatically given
    to every XML-RPC call before the arguments provides through (({method_missing})).
    
== Instance Methods
Every method call is forwarded to the XML-RPC server defined in ((<new|XMLRPC::Client::Proxy#new>)).
    
Note: Inherited methods from class (({Object})) cannot be used as XML-RPC names, because they get around
(({method_missing})). 
          


= History
    $Id: client.rb,v 1.34 2001/06/19 14:01:31 michael Exp $

=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "xmlrpc/config"
require "xmlrpc/utils"     # ParserWriterChooseMixin
require "net/http"

module XMLRPC

  class Client
   
    USER_AGENT = "XMLRPC::Client (Ruby #{RUBY_VERSION})"

    include ParserWriterChooseMixin

    def initialize(host, path="/RPC2", port=80, proxy_addr=nil, proxy_port=nil)
      @path = path
      Net::HTTP.version_1_1
      @http = Net::HTTP.new(host, port, proxy_addr, proxy_port)

      @parser = nil
      @create = nil
    end

    def call(method, *args)
      ok, param = call2(method, *args) 
      return param if ok
      raise param
    end 
  
    def multicall(*methods)
      ok, params = multicall2(*methods)
      return params if ok
      raise params 
    end

    def multicall2(*methods)
      ok, params = call2("system.multicall", 
        methods.collect {|m| {'methodName' => m[0], 'params' => m[1..-1]} }
      )

      if ok 
        params = params.collect do |param|
          if param.is_a? Array
            param
          elsif param.is_a? Hash
            XMLRPC::FaultException.new(param["faultCode"], param["faultString"])
          else
            raise "Wrong multicall return value"
          end 
        end
      end

      return ok, params
    end

 
    def call2(method, *args)

      request = create().methodCall(method, *args)

      resp, data = @http.post (
		     @path, 
		     request,
		     "User-Agent"     =>  USER_AGENT,
		     "Content-Type"   => "text/xml",
		     "Content-Length" => request.size.to_s 
		   )
      @http.finish

      if resp.code[0,1] != "2"
	raise "HTTP-Error: #{resp.code} #{resp.message}" 
      end

      if data.nil? or data.size == 0 or resp["Content-Length"].to_i != data.size
	raise "Wrong size"
      end

      if resp["Content-Type"] != "text/xml"
	raise "Wrong content-type"
      end

      parser().parseMethodResponse(data)
    end

    
    def proxy(prefix, *args)
      Proxy.new(self, prefix, args)
    end

    def proxy2(prefix, *args)
      Proxy.new(self, prefix, args, false)
    end



    class Proxy

      def initialize(server, prefix, args=[], call=true, delim=".")
	@server = server
	@prefix = prefix + delim
	@call   = call
	@args   = args 
      end

      def method_missing(mid, *args)
	pre = @prefix + mid.to_s
	arg = @args + args

	if @call
	  @server.call (pre, *arg)
	else
	  @server.call2(pre, *arg)
	end
      end

    end # class Proxy




  end # class Client

end # module XMLRPC

