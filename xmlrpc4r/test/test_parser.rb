#! /usr/bin/env ruby

#
# Testcase for Parser
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: test_parser.rb,v 1.1 2001/06/11 16:25:15 michael Exp $
#

require "runit/testcase"
require "xmlrpc/parser"


class Test_Parser < RUNIT::TestCase

  def setup
    @xml = File.readlines("files/xml1.xml").to_s
    @expected = File.readlines("files/xml1.expected").to_s
  end

  def test_xmlparser
    p = XMLRPC::XMLParser::XMLParser.new
    assert_equal(p.parseMethodResponse(@xml).inspect, @expected)
  end

  def test_nqxmlparser
    p = XMLRPC::XMLParser::NQXMLParser.new
    assert_equal(p.parseMethodResponse(@xml).inspect, @expected)
  end

end

