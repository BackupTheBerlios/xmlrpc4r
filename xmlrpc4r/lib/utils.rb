#
# Defines ParserWriterChooseMixin, which makes it possible to choose a
# different XML writer and/or XML parser then the default one.
# The Mixin is used in client.rb (class Client) and server.rb (class 
# BasicServer)
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: utils.rb,v 1.5 2001/07/03 13:16:27 michael Exp $ 
#

module XMLRPC

  #
  # This module enables a user-class to be marshalled
  # by XML-RPC for Ruby into a Hash, with one additional
  # key/value pair "___class___" => ClassName
  # 
  module Marshallable
    def __get_instance_variables
      instance_variables.collect {|var| [var[1..-1], eval(var)] }
    end

    def __set_instance_variable(key, value)
      eval("@#$1 = value") if key =~ /^([\w_][\w_0-9]*)$/
    end
  end


  module ParserWriterChooseMixin

    def set_writer(writer)
      @create = Create.new(writer)
    end

    def set_parser(parser)
      @parser = parser
    end

    private

    def create
      # if set_writer was not already called then call it now
      if @create.nil? then
	set_writer(Config::DEFAULT_WRITER.new)
      end
      @create
    end

    def parser
      # if set_parser was not already called then call it now
      if @parser.nil? then
	set_parser(Config::DEFAULT_PARSER.new)
      end
      @parser
    end

  end # module ParserWriterChooseMixin

  #
  # class which wraps a Service Interface definition, used
  # by BasicServer#add_ihandler
  #
  class ServiceInterface
    def initialize(prefix, &p)
      raise "No interface specified" if p.nil?
      @prefix  = prefix
      @methods = []
      instance_eval &p
    end

    def get_prefix
      @prefix
    end

    def get_methods
      @methods
    end

    def add_method(sig, help=nil, meth_name=nil)
      mname = nil
      sig = [sig] if sig.kind_of? String

      sig = sig.collect do |s| 
        name, si = parse_sig(s)
        raise "Wrong signatures!" if mname != nil and name != mname 
        mname = name
        si
      end

      @methods << [mname, meth_name || mname, sig, help]
    end

    private # ---------------------------------
  
    def meth(*a)
      add_method(*a)
    end

    def parse_sig(sig)
      # sig is a String, returned will be 
      if sig =~ /^\s*(\w+)\s+([^(]+)(\(([^)]*)\))?\s*$/
        params = [$1]
        name   = $2.strip 
        $4.split(",").each {|i| params << i.strip} if $4 != nil
        return name, params
      else
        raise "Syntax error in signature"
      end
    end

  end # class Interface

  # 
  # short-form to create a ServiceInterface
  #
  def self.interface(prefix, &p)
    ServiceInterface.new(prefix, &p)  
  end

end # module XMLRPC

