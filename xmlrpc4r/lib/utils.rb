#
# Defines ParserWriterChooseMixin, which makes it possible to choose a
# different XML writer and/or XML parser then the default one.
# The Mixin is used in client.rb (class Client) and server.rb (class 
# BasicServer)
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: utils.rb,v 1.3 2001/06/21 11:38:12 michael Exp $ 
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

end # module XMLRPC

