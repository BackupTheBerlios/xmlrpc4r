#! /usr/bin/env ruby

#
# Testcase for Parser
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: test_parser.rb,v 1.2 2001/06/20 09:56:44 michael Exp $
#

require "runit/testcase"
require "xmlrpc/parser"


class Test_Parser < RUNIT::TestCase

  def setup
    @xml1 = File.readlines("files/xml1.xml").to_s
    @expected1 = File.readlines("files/xml1.expected").to_s.chomp

    @xml2 = File.readlines("files/value.xml").to_s
    @expected2 = File.readlines("files/value.expected").to_s.chomp
  end

  def test_xmlparser1
    p = XMLRPC::XMLParser::XMLParser.new
    assert_equal(p.parseMethodResponse(@xml1).inspect, @expected1)
  end

  def test_nqxmlparser1
    p = XMLRPC::XMLParser::NQXMLParser.new
    assert_equal(p.parseMethodResponse(@xml1).inspect, @expected1)
  end

  # ----------------------------------------------------------

  def test_xmlparser2
    p = XMLRPC::XMLParser::XMLParser.new
    assert_equal(p.parseMethodCall(@xml2).inspect, @expected2)
  end

  def test_nqxmlparser2
    p = XMLRPC::XMLParser::NQXMLParser.new
    assert_equal(p.parseMethodCall(@xml2).inspect, @expected2)
   end

end

