#!/usr/bin/env ruby

# 
# $Id: install.rb,v 1.1 2001/01/26 13:25:34 michael Exp $
# Install XML-RPC
#

DIR   = "xmlrpc"
FILES = %w(cgi_server.rb client.rb create.rb parser.rb)


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

  

