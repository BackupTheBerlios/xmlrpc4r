#
# Defines ParserWriterChooseMixin, which makes it possible to choose a
# different XML writer and/or XML parser then the default one.
# The Mixin is used in client.rb (class Client) and server.rb (class 
# BasicServer)
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: utils.rb,v 1.1 2001/04/20 13:34:52 michael Exp $ 
#

module XMLRPC

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
	set_writer(XMLWriter::DEFAULT_WRITER.new)
      end
      @create
    end

    def parser
      # if set_parser was not already called then call it now
      if @parser.nil? then
	set_parser(XMLParser::DEFAULT_PARSER.new)
      end
      @parser
    end

  end # module ParserWriterChooseMixin

end # module XMLRPC

