require "xmlrpc/client"
 
server = XMLRPC::Client.new("localhost", "/cgi-bin/xml.cgi", 8070)

p server.multicall( 
  ['michael.add', 4, 5],
  ['michael.sub', 4, 3]
)

p server.call('system.multicall', [ 
    { 'methodName' => 'michael.add', 'params'     => [4, 5] },
    { 'methodName' => 'michael.sub', 'params'     => [4, 3] }
])

