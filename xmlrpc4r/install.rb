#!/usr/bin/env ruby

# 
# $Id: install.rb,v 1.4 2001/01/28 17:37:43 michael Exp $
# Install XML-RPC
#

DIR   = "xmlrpc"
FILES = %w(EServer.rb base64.rb client.rb create.rb httpserver.rb parser.rb server.rb)


require "rbconfig"
require "ftools"
include Config

RV = CONFIG["MAJOR"] + "." + CONFIG["MINOR"]
DSTPATH = CONFIG["sitedir"] + "/" +  RV + "/" + DIR



begin
  File.mkpath DSTPATH, true 
  
  for name in FILES do
    File.install "lib/#{name}", "#{DSTPATH}/#{name}", 0644, true   
  end
rescue 
  puts "install failed!"
  puts $!
else
  puts "install succeed!"
end

  

