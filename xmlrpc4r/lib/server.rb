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
    The default-handler is called with the method-name as first argument, and
    the other arguments are the parameters given by the client-call.


=end



require "xmlrpc/parser"
require "xmlrpc/create"
require "xmlrpc/httpserver"

module XMLRPC


class BasicServer

  def initialize(class_delim=".")
    @handler = []
    @default_handler = proc {|*a| def_handler(*a)} 
    @create = XMLRPC::Create.new
    @class_delim = class_delim
  end

  def add_handler(prefix, obj=nil, &block)
    if obj.nil? and block.nil? 
      raise ArgumentError, "Too less parameters"
    elsif ! obj.nil? and ! block.nil?
      raise ArgumentError, "Too much parameters"
    else
      if ! obj.nil?
        @handler << [prefix + @class_delim, obj]
      elsif ! block.nil?
        @handler << [prefix, block]   
      else
        raise "unexpected error"
      end
    end
  end

  
  def get_default_handler
    @default_handler
  end

  def set_default_handler (&handler)
    if handler.nil? 
      raise ArgumentError, "No block given"
    else
      @default_handler = handler
    end
  end  

  private
 
  #
  # method dispatch
  #
  def dispatch(methodname, *args)
    for name, obj in @handler do

      if obj.kind_of? Proc  
        return obj.call(*args) if methodname == name
      else
        if methodname =~ /^#{name}(.+)$/ 
          return obj.send($1, *args) if obj.respond_to? $1
        end
      end
        
    end 
    
    @default_handler.call(methodname, *args) 
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
    @create.methodResponse(*res) 
  end

  #
  # is called when no other method is 
  # responsible for the request
  #
  def def_handler(methodname, *args)
    raise XMLRPC::FaultException.new(-99, "Method <#{methodname}> missing!")
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
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing")
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

    parser = Parser.new
   
    length = ENV['CONTENT_LENGTH'].to_i

    http_error(405, "Method Not Allowed") unless ENV['REQUEST_METHOD'] == "POST" 
    http_error(400, "Bad Request")        unless ENV['CONTENT_TYPE'] == "text/xml"
    http_error(411, "Length Required")    unless length > 0 

    $stdin.binmode
    data = $stdin.read(length)

    http_error(400, "Bad Request")        if data.nil? or data.size != length

    @method, @params = parser.parseMethodCall(data) 
  end
  
  def serve
    resp = handle(@method, *@params)
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
    h.each {|key, value| str += "#{key}: #{value}\r\n"}
    str += "\r\n#{body}"

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
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing")
    end
 
    s.serve

== Description
Implements a standalone XML-RPC server.

== Superclass
((<XMLRPC::BasicServer>))

== Class Methods
--- XMLRPC::Server.new( port=8080, *a )
    Creates a new (({XMLRPC::Server})) instance, which is a XML-RPC server listening on
    port ((|port|)). The server is not started, to start it you have to call ((<serve|XMLRPC::Server#serve>)).
    All additionally given parameters in ((|*a|)) are by-passed to ((<XMLRPC::BasicServer.new>)). 

== Instance Methods
--- XMLRPC::Server#serve
    Call this after you have added all you handlers to the server.
    This method starts the server to listen for XML-RPC requests and answer them.

--- XMLRPC::Server#stop
    Stops the server.
    
=end

class Server < BasicServer

  def initialize(port=8080, *a)
    super(*a)
    @server = ::HttpServer.new(proc {|data| request_handler(data)}, port) 
    @parser = Parser.new
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
    method, params = @parser.parseMethodCall(data) 
    handle(method, *params)
   end
  
end

end # module XMLRPC


=begin
= History
    $Id: server.rb,v 1.15 2001/01/29 17:27:03 michael Exp $    
=end

