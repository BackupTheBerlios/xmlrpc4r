=begin
= xmlrpc4r - XML-RPC for Ruby
Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)

Released under the same term of license as Ruby.

== What is XML-RPC ?
XML-RPC provides remote procedure calls over HTTP with XML. It is like SOAP but
much easier. For more information see the XML-RPC homepage 
((<URL:http://www.xmlrpc.com/>)).

== HOWTO
See ((<here|URL:howto.html>)).

== Documentation
* ((<Base64|URL:base64.html>)) 
* ((<DateTime|URL:datetime.html>)) 
* ((<Client|URL:client.html>)) 
* ((<Server|URL:server.html>)) 

== Features

: Extensions
* Introspection
* multiCall
* optionally nil values and integers larger than 32 Bit
: Server
* Standalone XML-RPC server
* CGI-based (works with FastCGI)

: Client
* synchronous/asynchronous calls
* Basic HTTP-401 Authentification
* HTTPS protocol (SSL)

: General
* possible to choose between XMLParser Module (Expat wrapper) and NQXML (pure Ruby) parsers
* Marshalling Ruby objects to Hashs and reconstruct them later from a Hash
* SandStorm component architecture Client interface


== ChangeLog
See ((<here|URL:ChangeLog.html>)).

== Download
xmlrpc4r can be downloaded from here:

* Version 1.6.7:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_7.tar.gz>))

* Version 1.6.6:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_6.tar.gz>))

* Version 1.6.5:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_5.tar.gz>))

* Version 1.6.4:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_4.tar.gz>))

* Version 1.6.3:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_3.tar.gz>))

* Version 1.6.2:

  ((<URL:http://www.fantasy-coders.de/ruby/xmlrpc4r/xmlrpc4r-1_6_2.tar.gz>))


== Further information
For more information on installation and prerequisites read the (('README')) 
file of the package.

== History
    $Id: index.rd,v 1.22 2001/07/02 15:17:42 michael Exp $

=end
