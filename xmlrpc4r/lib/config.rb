#
# $Id: config.rb,v 1.2 2001/06/19 13:26:10 michael Exp $
# Configuration file for XML-RPC for Ruby
#

module XMLRPC

  module XMLWriter
    DEFAULT_WRITER = Simple # or XMLParser
  end

  module XMLParser
    DEFAULT_PARSER = XMLParser # or NQXMLParser
  end

  module Extensions
    ENABLE_NIL_CREATE = false
    ENABLE_NIL_PARSER = false
    
    # allows integers greater than 32-bit if true
    ENABLE_BIGINT     = false
  end
  

end

