#!/usr/bin/env ruby

#
# This sample demonstrates how to call the XML-RPC interface
# of RAA (Ruby Application Archive)
#
# $Id: raa_test.rb,v 1.1 2001/03/22 20:07:20 michael Exp $
#

require "xmlrpc/client"

server = XMLRPC::Client.new("www.ruby-lang.org", "/~nahi/xmlrpc/raa/")
raa = server.proxy("raa")

klass = Struct.new( "Category" , :major, :minor)
category = klass.new( "Library", "XML")



p raa.getAllListings
p raa.getProductTree



p raa.getInfoFromCategory( category )
p raa.getModifiedInfoSince( Time.at( Time.now.to_i - 24 * 3600 ) )
p raa.getInfoFromName( "XML-RPC" )


