#
# Implements a BasicServer and CGIServer
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: server.rb,v 1.3 2001/01/27 19:42:55 michael Exp $
#


require "xmlrpc/parser"
require "xmlrpc/create"

module XMLRPC


class BasicServer

  attr_accessor :default_handler

  def initialize
    @handler = []
    @default_handler = proc {|*a| def_handler(*a)} 
    @create = XMLRPC::Create.new
  end

  def add_handler(prefix, obj=nil, &block)
    if obj.nil? and block.nil? 
      raise ArgumentError, "Too less parameters"
    elsif ! obj.nil? and ! block.nil?
      raise ArgumentError, "Too much parameters"
    else
      @handler << [prefix, obj || block ]   
    end
  end


  def serve
    raise NotImplementedError, "abstract method"
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
= Synopsis
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
=end

class CGIServer < BasicServer
  @@obj = nil

  attr_reader :method, :params
  
  def CGIServer.new
    @@obj = super if @@obj.nil?
    @@obj
  end

  def initialize
    super
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

