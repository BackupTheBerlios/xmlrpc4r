=begin

= XMLRPC::BasicServer
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

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

    A handler method or code-block can return the types listed 
    ((<here|URL:client.html#index:0>)). When a method fails, it can
    tell it the client by throwing an (({XMLRPC::FaultException})) like
    in this example:
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

--- XMLRPC::BasicServer#default_handler
    Returns the default-handler, which is called when no handler for
    a method-name is found.
    It is a (({Proc})) object.

--- XMLRPC::BasicServer#default_handler= ( handler )
    Sets ((|handler|)) as the default-handler, which is called when 
    no handler for a method-name is found. ((|handler|)) should be a 
    (({Proc})) object.


=end



require "xmlrpc/parser"
require "xmlrpc/create"

module XMLRPC


class BasicServer

  attr_accessor :default_handler

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
    raise "Method missing"
  end

end


=begin
= XMLRPC::CGIServer
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

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

    s.serve

== Description
Implements an CGI-based XML-RPC server.

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
= History
    $Id: server.rb,v 1.5 2001/01/27 23:05:17 michael Exp $    
=end

class CGIServer < BasicServer
  @@obj = nil

  def CGIServer.new(*a)
    @@obj = super(*a) if @@obj.nil?
    @@obj
  end

  def initialize(*a)
    super(*a)
    $stdin.binmode
    data = $stdin.read(ENV['CONTENT_LENGTH'].to_i)
    parser = Parser.new
    @method, @params = parser.parseMethodCall(data) 
  end
  
  def serve
    resp = handle(@method, *@params)
    puts "Content-type: text/xml"
    puts "Content-length: #{resp.size}"
    puts
    puts resp
  end

end



end # module XMLRPC

