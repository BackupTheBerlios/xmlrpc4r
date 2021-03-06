#!/usr/bin/env ruby

# 
# $Id: install.rb,v 1.8 2001/06/19 12:27:45 michael Exp $
# Install XML-RPC
#

DIR   = "xmlrpc"
FILES = %w(GServer.rb base64.rb client.rb config.rb create.rb datetime.rb httpserver.rb parser.rb server.rb utils.rb)


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

  

