#
# $Id: config.rb,v 1.1 2001/06/19 12:26:56 michael Exp $
# Configuration file for XML-RPC for Ruby
#

module XMLRPC

  module XMLWriter
    DEFAULT_WRITER = Simple # or XMLParser
  end

  module XMLParser
    DEFAULT_PARSER = XMLParser # or NQXMLParser
  end

end

