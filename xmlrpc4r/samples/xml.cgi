#!/usr/bin/env ruby


require "xmlrpc/server"


s = XMLRPC::CGIServer.new

s.add_handler("michael.add") {|a,b|
  a+b
}  
s.add_handler("michael.div") {|a,b|
  if b == 0
    raise XMLRPC::FaultException.new 1, "division by zero"
  else
    a / b
  end
}

s.serve

