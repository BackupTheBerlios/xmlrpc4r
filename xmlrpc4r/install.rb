#!/usr/bin/env ruby

# 
# $Id: install.rb,v 1.2 2001/01/26 14:33:50 michael Exp $
# Install XML-RPC
#

DIR   = "xmlrpc"
FILES = %w(base64.rb cgi_server.rb client.rb create.rb parser.rb)


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

  

