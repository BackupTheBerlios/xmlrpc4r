=begin
= xmlrpc4r - HOWTO
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

= Install
You need James Clark's XML Parser Toolkit "expat" installed, to install
the the Expat Module for Ruby "xmlparser", which is
available from RAA (Ruby Application Archive - ((<URL:http://www.ruby-lang.org/en/raa.html>)))  
and was made by Yoshida Masato.
"xmlrpc4r" is based on "xmlparser".
Then you'll need "xmlrpc4r" of course, which is available at
((<URL:http://www.s-direktnet.de/homepages/neumann/xmlrpc4r>)).

To install xmlrpc4r:
  tar -xvzf xmlrpc4r-1_5_3.tar.gz
  cd xmlrpc4r-1_5_3
  su root -c "ruby install.rb"


= Samples

== Client

  require "xmlrpc/client"
  
  # Make an object to represent the XML-RPC server.
  server = XMLRPC::Client.new( "xmlrpc-c.sourceforge.net", "/api/sample.php")

  # Call the remote server and get our result
  result = server.call("sample.sumAndDifference", 5, 3)

  sum = result["sum"]
  difference = result["difference"]

  puts "Sum: #{sum}, Difference: #{difference}"

== Client with XML-RPC fault-structure handling

There are two possible ways, of handling a fault-structure:

=== by catching a XMLRPC::FaultException exception 

  require "xmlrpc/client"

  # Make an object to represent the XML-RPC server.
  server = XMLRPC::Client.new( "xmlrpc-c.sourceforge.net", "/api/sample.php")

  begin
    # Call the remote server and get our result
    result = server.call("sample.sumAndDifference", 5, 3)

    sum = result["sum"]
    difference = result["difference"]

    puts "Sum: #{sum}, Difference: #{difference}"

  rescue XMLRPC::FaultException => e
    puts "Error: "
    puts e.faultCode
    puts e.faultString
  end
   
=== by calling "call2" which returns a boolean

  require "xmlrpc/client"

  # Make an object to represent the XML-RPC server.
  server = XMLRPC::Client.new( "xmlrpc-c.sourceforge.net", "/api/sample.php")

  # Call the remote server and get our result
  ok, result = server.call2("sample.sumAndDifference", 5, 3)

  if ok
    sum = result["sum"]
    difference = result["difference"]

    puts "Sum: #{sum}, Difference: #{difference}"
  else
    puts "Error: "
    puts result.faultCode
    puts result.faultString
  end
   
== CGI-based Server

There are also two ways to define handler, the first is
like C/PHP, the second like Java, of course both ways
can be mixed:

=== C/PHP-like (handler functions)

  require "xmlrpc/server"

  s = XMLRPC::CGIServer.new

  s.add_hanlder("sample.sumAndDifference") do |a,b|
    { "sum" => a + b, "difference" => a - b }
  end
    
  s.serve

=== Java-like (handler classes)

  require "xmlrpc/server"

  s = XMLRPC::CGIServer.new

  class MyHandler
    def sumAndDifference(a, b)
      { "sum" => a + b, "difference" => a - b }
    end
  end
    
  s.add_handler("sample", MyHandler.new)
  s.serve


To return a fault-structre you have to raise an FaultException e.g.:
  raise XMLRPC::FaultException.new(3, "division by Zero")


== Standalone server

Same as CGI-based server, only that the line
  server = XMLRPC::CGIServer.new
must be changed to
  server = XMLRPC::Server.new(8080)
if you want a server listening on port 8080.
The rest is the same.


= History
  $Id: howto.rd,v 1.1 2001/02/07 23:37:39 michael Exp $
=end

