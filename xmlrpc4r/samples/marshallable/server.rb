#!/usr/bin/env ruby

require "xmlrpc/server"
require "person"

s = XMLRPC::Server.new(8070)

s.add_handler("test.person") {
  obj = Person.new
  obj.name = "Michael"
  obj.age  = 21

  obj
}
s.serve

