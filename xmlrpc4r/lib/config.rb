#
# $Id: config.rb,v 1.5 2001/06/21 11:38:12 michael Exp $
# Configuration file for XML-RPC for Ruby
#

module XMLRPC

  module Config

    DEFAULT_WRITER = XMLWriter::Simple    # or XMLWriter::XMLParser
    DEFAULT_PARSER = XMLParser::XMLParser # or XMLParser::NQXMLParser

    # enable <nil/> tag
    ENABLE_NIL_CREATE    = false
    ENABLE_NIL_PARSER    = false
    
    # allows integers greater than 32-bit if true
    ENABLE_BIGINT        = false

    # enable marshalling ruby objects which include XMLRPC::Marshallable
    ENABLE_MARSHALLING   = true 

    # enable multiCall extension by default
    ENABLE_MULTICALL     = false
    
    # enable Introspection extension by default
    ENABLE_INTROSPECTION = false

  end


=begin
  module XMLWriter
    DEFAULT_WRITER = Simple # or XMLParser
  end

  module XMLParser
    DEFAULT_PARSER = XMLParser # or NQXMLParser
  end

  module Extensions
    # enable <nil/> tag
    ENABLE_NIL_CREATE  = false
    ENABLE_NIL_PARSER  = false
    
    # allows integers greater than 32-bit if true
    ENABLE_BIGINT      = false

    # enable marshalling ruby objects which include XMLRPC::Marshallable
    ENABLE_MARSHALLING = true 
  end
=end

end

