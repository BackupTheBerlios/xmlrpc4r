#
# Implements a simple HTTP-server by using John W. Small's (jsmall@laser.net) 
# ruby-generic-server, which I have renamed from Server.rb to EServer.rb
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: httpserver.rb,v 1.3 2001/01/29 11:47:03 michael Exp $
#



require "xmlrpc/EServer"

class HttpServer < Server

  def serve(io)
    command = io.gets
    hash = {}

    while (line=io.gets) !~ /^(\n|\r)/
      if line =~ /^([\w-]+):\s*(.*)$/
	hash[$1.upcase] = $2.strip
      end
    end
    
    body = io.read(hash["CONTENT-LENGTH"].to_i)
    resp = @handler.call(body) 

    io.puts "HTTP/1.0 200 OK"
    io.puts "Connection: close" 
    io.puts "Content-Length: #{resp.size}" 
    io.puts "Content-type: text/xml"
    io.puts "Server: XMLRPC::Server (Ruby #{RUBY_VERSION})"
    io.puts
    io.puts resp
  end


  def initialize(handler, port=8080, maxConnections = 4, 
                 stdlog = $stdout, audit = true, debug = true)
    @handler = handler
    super(port, maxConnections, stdlog, audit, debug)
  end

end


