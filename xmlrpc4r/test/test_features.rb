#! /usr/bin/env ruby

#
# Testcase for Parser
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: test_features.rb,v 1.2 2001/06/21 11:38:29 michael Exp $
#

require "runit/testcase"
require "xmlrpc/create"
require "xmlrpc/parser"

module XMLRPC
module Config
  ENABLE_NIL_CREATE = true
  ENABLE_NIL_PARSER = true
end
end

class Test_Features < RUNIT::TestCase

  def setup
    @c = [ XMLRPC::Create.new(XMLRPC::XMLWriter::Simple.new),
           XMLRPC::Create.new(XMLRPC::XMLWriter::XMLParser.new) ]

    @p = [ XMLRPC::XMLParser::NQXMLParser.new, XMLRPC::XMLParser::XMLParser.new ]
  end

  def test_nil
    params = [nil, {"test" => nil}, [nil, 1, nil]]

    @c.each do |c| 
      str = c.methodCall("test", *params) 
      @p.each do |p|
        para = p.parseMethodCall(str)
        assert_equal(para[1], params)
      end
    end
  end

end

