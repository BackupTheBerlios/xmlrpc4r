#
# Implements a simple HTTP-server by using John W. Small's (jsmall@laser.net) 
# ruby-generic-server, which I have renamed from Server.rb to EServer.rb
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: httpserver.rb,v 1.5 2001/01/29 16:19:34 michael Exp $
#



require "xmlrpc/EServer"

class HttpServer < Server

  def http_error(status, message, io)
    io.puts "HTTP/1.0 #{status} {message}"
    io.puts "Connection: close" 
    io.puts "Server: XMLRPC::Server (Ruby #{RUBY_VERSION})"
    io.puts
  end

  def serve(io)
    if io.gets =~ /^(\S+)\s+(\S+)\s+(\S+)/
      method = $1
      path = $2
      proto = $3
    else
      http_error(400, "Bad Request", io) 
      return 
    end

    if method != "POST" 
      http_error(405, "Method Not Allowed", io)
      return
    end

    header = {}
    while (line=io.gets) !~ /^(\n|\r)/
      if line =~ /^([\w-]+):\s*(.*)$/
	header[$1.capitalize] = $2.strip
      end
    end

    length = header['Content-length'].to_i

    if header['Content-type'] != "text/xml"
      http_error(400, "Bad Request", io)
      return
    end 
    unless length > 0
      http_error(411, "Length Required", io)
      return
    end

    io.binmode
    data = io.read(length)

    if data.nil? or data.size != length
      http_error(400, "Bad Request", io)
      return
    end

    begin
      resp = @handler.call(body) 
      raise if resp.nil? or resp.size <= 0
    rescue Exception => e
      http_error(500, "Internal Server Error", io)
      return
    end
    
    io.puts "HTTP/1.0 200 OK"
    io.puts "Connection: close" 
    io.puts "Content-Length: #{resp.size}" 
    io.puts "Content-type: text/xml"
    io.puts "Server: XMLRPC::Server (Ruby #{RUBY_VERSION})"
    io.puts
    io.print resp

  end

end


  def initialize(handler, port=8080, maxConnections = 4, 
                 stdlog = $stdout, audit = true, debug = true)
    @handler = handler
    super(port, maxConnections, stdlog, audit, debug)
  end

end


