=begin
= xmlrpc/server.rb
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

= Classes
* ((<XMLRPC::BasicServer>))
* ((<XMLRPC::CGIServer>))
* ((<XMLRPC::Server>))

= XMLRPC::BasicServer
== Description
Is the base class for all XML-RPC server-types (CGI, standalone).
You can add handler and set a default handler. 
Do not use this server, as this is/should be an abstract class.

=== How the method to call is found
The arity (number of accepted arguments) of a handler (method or (({Proc})) object) is 
compared to the given arguments submitted by the client for a RPC ((-Remote Procedure Call-)). 
A handler is only called if it accepts the number of arguments, otherwise the search 
for another handler will go on. When at the end no handler was found, 
the ((<default_handler|XMLRPC::BasicServer#set_default_handler>)) will be called.
With this technique it is possible to do overloading by number of parameters, but
only for (({Proc})) handler, because you cannot define two methods of the same name in
the same class. 


== Class Methods
--- XMLRPC::BasicServer.new( class_delim="." )
    Creates a new (({XMLRPC::BasicServer})) instance, which should not be 
    done, because (({XMLRPC::BasicServer})) is an abstract class. This
    method should be called from a subclass indirectly by a (({super})) call
    in the method (({initialize})). The paramter ((|class_delim|)) is used
    in ((<add_handler|XMLRPC::BasicServer#add_handler>)) when an object is
    added as handler, to delimit the object-prefix and the method-name.

== Instance Methods
--- XMLRPC::BasicServer#add_handler( prefix, obj=nil, &block )
    This method has two forms, one for adding an object and one to
    add a code block as a handler of a XML-RPC call.
    To add an object write:
        server.add_handler("michael", MyHandlerClass.new)
    All public methods of (({MyHandlerClass})) are accessible to
    the XML-RPC clients by (('michael."name of method"')). This is 
    where the ((|class_delim|)) in ((<new|XMLRPC::BasicServer.new>)) 
    has it's role, a XML-RPC method-name is defined by 
    ((|prefix|)) + ((|class_delim|)) + (('"name of method"')). 
    To add a code block as a handler, write:
        server.add_handler("michael.add") {|a,b| a+b}
    Here the ((|prefix|)) is the full name of the method. 

    A handler method or code-block can return the types listed at
    ((<XMLRPC::Client#call|URL:client.html#index:0>)). 
    When a method fails, it can tell it the client by throwing an 
    (({XMLRPC::FaultException})) like in this example:
        s.add_handler("michael.div") do |a,b|
          if b == 0
            raise XMLRPC::FaultException.new(1, "division by zero")
          else
            a / b 
          end
        end 
    The client gets in the case of (({b==0})) an object back of type
    (({XMLRPC::FaultException})) that has a ((|faultCode|)) and ((|faultString|))
    field.

--- XMLRPC::BasicServer#get_default_handler
    Returns the default-handler, which is called when no handler for
    a method-name is found.
    It is a (({Proc})) object.

--- XMLRPC::BasicServer#set_default_handler ( &handler )
    Sets ((|handler|)) as the default-handler, which is called when 
    no handler for a method-name is found. ((|handler|)) is a code-block.
    The default-handler is called with the (XML-RPC) method-name as first argument, and
    the other arguments are the parameters given by the client-call.
  
    If no block is specified the default of (({XMLRPC::BasicServer})) is used, which is it's 
    method default_handler.


--- XMLRPC::BasicServer#set_writer( writer )
    Sets the XML writer to use for generating XML output.
    Should be an instance of a class from module (({XMLRPC::XMLWriter})).
    If this method is not called, then (({XMLRPC::XMLWriter::DEFAULT_WRITER})) is used. 

--- XMLRPC::BasicServer#set_parser( parser )
    Sets the XML parser to use for parsing XML documents.
    Should be an instance of a class from module (({XMLRPC::XMLParser})).
    If this method is not called, then (({XMLRPC::XMLParser::DEFAULT_WRITER})) is used.

--- XMLRPC::BasicServer#add_introspection( prefix="system" )
    Adds the introspection handlers "listMethods", "methodSignature" and "methodHelp", 
    where only the first one works.
    Note that method method names of class-handlers which occur in (({Object})) are not
    shown.

--- XMLRPC::BasicServer#get_service_hook
    Returns the service-hook, which is called on each service request (RPC) unless it's (({nil})).

--- XMLRPC::BasicServer#set_service_hook ( &handler )
    A service-hook is called for each service request (RPC).
    You can use a service-hook for example to wrap existing methods and catch exceptions of them or
    convert values to values recognized by XMLRPC. You can disable it by passing (({nil})) as parameter  
    ((|handler|)) .

    The service-hook is called with a (({Proc})) object and with the parameters for this (({Proc})).
    An example:

       server.set_service_hook {|obj, *args|
         begin
           ret = obj.call(*args)  # call the original service-method
           # could convert the return value 
         resuce
           # rescue exceptions
         end
       }

=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "xmlrpc/httpserver"
require "xmlrpc/utils"         # ParserWriterChooseMixin



module XMLRPC


class BasicServer

  include ParserWriterChooseMixin

  def initialize(class_delim=".")
    @handler = []
    @default_handler = method( :default_handler).to_proc
    @service_hook = nil

    @class_delim = class_delim
    @create = nil
    @parser = nil
  end

  def add_handler(prefix, obj=nil, &block)
    if obj.nil? and block.nil? 
      raise ArgumentError, "Too few parameters"
    elsif ! obj.nil? and ! block.nil?
      raise ArgumentError, "Too many parameters"
    else
      if ! obj.nil?
        @handler << [prefix + @class_delim, obj]
      elsif ! block.nil?
        @handler << [prefix, block]   
      else
        raise "Unexpected error"
      end
    end
  end

  def get_service_hook
    @service_hook
  end

  def set_service_hook(&handler)
    @service_hook = handler
  end
 
  def get_default_handler
    @default_handler
  end

  def set_default_handler (&handler)
    if handler.nil? 
      @default_handler = method( :default_handler).to_proc
    else
      @default_handler = handler
    end
  end  

  

  def add_introspection(prefix="system")
    add_handler(prefix + @class_delim + "listMethods") do
      methods = []
      @handler.each do |name, obj|
        if obj.kind_of? Proc
          methods << name
        else
          (obj.methods - Object.methods).each {|meth| methods << name + meth}
        end
      end
      methods
    end

    add_handler(prefix + @class_delim + "methodSignature") do |meth|
      "Not implemented"
    end

    add_handler(prefix + @class_delim + "methodHelp") do |meth|
      "Not implemented"
    end
  end
 
  private # --------------------------------------------------------------
 
  #
  # method dispatch
  #
  def dispatch(methodname, *args)
    for name, obj in @handler
      if obj.kind_of? Proc
	next unless methodname == name
      else
	next unless methodname =~ /^#{name}(.+)$/
	obj = obj.method($1) if obj.respond_to? $1
      end

      if check_arity(obj, args.size)
        if @service_hook.nil?
          return obj.call(*args) 
        else
          return @service_hook.call(obj, *args)
        end
      end
    end 
 
    @default_handler.call(methodname, *args) 
  end


  #
  # returns true, if the arity of "obj" matches
  #
  def check_arity(obj, n_args)
    ary = obj.arity

    if ary >= 0
      n_args == ary
    else
      n_args >= (ary+1).abs 
    end
  end

  #
  #
  #
  def handle(methodname, *args)
    res = begin
      [true, dispatch(methodname, *args)]
    rescue XMLRPC::FaultException => e  
      [false, e]  
    end
    create().methodResponse(*res) 
  end

  #
  # is called when no other method is 
  # responsible for the request
  #
  def default_handler(methodname, *args)
    raise XMLRPC::FaultException.new(-99, "Method <#{methodname}> missing or wrong number of parameters!")
  end
 
end


=begin
= XMLRPC::CGIServer
== Synopsis
    require "xmlrpc/server"
 
    s = XMLRPC::CGIServer.new     

    s.add_handler("michael.add") do |a,b|
      a + b
    end

    s.add_handler("michael.div") do |a,b|
      if b == 0
        raise XMLRPC::FaultException.new(1, "division by zero")
      else
        a / b 
      end
    end 

    s.set_default_handler do |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
                                       " or wrong number of parameters!")
    end
  
    s.serve

== Description
Implements a CGI-based XML-RPC server.

== Superclass
((<XMLRPC::BasicServer>))

== Class Methods
--- XMLRPC::CGIServer.new( *a )
    Creates a new (({XMLRPC::CGIServer})) instance. All parameters given
    are by-passed to ((<XMLRPC::BasicServer.new>)). You can only create 
    ((*one*)) (({XMLRPC::CGIServer})) instance, because more than one makes
    no sense.

== Instance Methods
--- XMLRPC::CGIServer#serve
    Call this after you have added all you handlers to the server.
    This method processes a XML-RPC methodCall and sends the answer
    back to the client. 
    Make sure that you don't write to standard-output in a handler, or in
    any other part of your program, this would case a CGI-based server to fail!
=end

class CGIServer < BasicServer
  @@obj = nil

  def CGIServer.new(*a)
    @@obj = super(*a) if @@obj.nil?
    @@obj
  end

  def initialize(*a)
    super(*a)
  end
  
  def serve
    length = ENV['CONTENT_LENGTH'].to_i

    http_error(405, "Method Not Allowed") unless ENV['REQUEST_METHOD'] == "POST" 
    http_error(400, "Bad Request")        unless ENV['CONTENT_TYPE'] == "text/xml"
    http_error(411, "Length Required")    unless length > 0 

    $stdin.binmode
    data = $stdin.read(length)

    http_error(400, "Bad Request")        if data.nil? or data.size != length

    method, params = parser().parseMethodCall(data) 

    resp = handle(method, *params)
    http_write(resp, "Content-type" => "text/xml")
  end


  private

  def http_error(status, message)
    err = "#{status} #{message}"
    msg = <<-"MSGEND" 
      <html>
        <head>
          <title>#{err}</title>
        </head>
        <body>
          <h1>#{err}</h1>
          <p>Unexpected error occured while processing XML-RPC request!</p>
        </body>
      </html>
    MSGEND

    http_write(msg, "Status" => err, "Content-type" => "text/html")
    exit 
  end

  def http_write(body, header)
    h = {}
    header.each {|key, value| h[key.to_s.capitalize] = value}
    h['Status']         ||= "200 OK"
    h['Content-length'] ||= body.size.to_s 

    str = ""
    h.each {|key, value| str << "#{key}: #{value}\r\n"}
    str << "\r\n#{body}"

    print str
  end

end


=begin
= XMLRPC::Server
== Synopsis
    require "xmlrpc/server"
 
    s = XMLRPC::Server.new(8080) 

    s.add_handler("michael.add") do |a,b|
      a + b
    end

    s.add_handler("michael.div") do |a,b|
      if b == 0
        raise XMLRPC::FaultException.new(1, "division by zero")
      else
        a / b 
      end
    end 

    s.set_default_handler do |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
                                       " or wrong number of parameters!")
    end
 
    s.serve

== Description
Implements a standalone XML-RPC server.

== Superclass
((<XMLRPC::BasicServer>))

== Class Methods
--- XMLRPC::Server.new( port=8080, host="127.0.0.1", *a )
    Creates a new (({XMLRPC::Server})) instance, which is a XML-RPC server listening on
    port ((|port|)) and accepts requests for the host ((|host|)), which is by default only the localhost. 
    The server is not started, to start it you have to call ((<serve|XMLRPC::Server#serve>)).
    All additionally given parameters in ((|*a|)) are by-passed to ((<XMLRPC::BasicServer.new>)). 

== Instance Methods
--- XMLRPC::Server#serve
    Call this after you have added all you handlers to the server.
    This method starts the server to listen for XML-RPC requests and answer them.

--- XMLRPC::Server#stop
    Stops the server.
    
=end

class Server < BasicServer

  def initialize(port=8080, host="127.0.0.1", *a)
    super(*a)
    @server = ::HttpServer.new(proc {|data| request_handler(data)}, port, host)
  end
  
  def serve
    begin
      @server.start.join
    ensure
      @server.stop
    end
  end
  
  def stop
    @server.stop
  end

 
  private

  def request_handler(data)
    $stderr.puts "in request_handler" if $DEBUG
    method, params = parser().parseMethodCall(data) 
    handle(method, *params)
   end
  
end

end # module XMLRPC


=begin
= History
    $Id: server.rb,v 1.25 2001/06/09 18:09:24 michael Exp $    
=end

