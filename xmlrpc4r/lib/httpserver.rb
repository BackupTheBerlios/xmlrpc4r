#
# Implements a simple HTTP-server by using John W. Small's (jsmall@laser.net) 
# ruby-generic-server.
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: httpserver.rb,v 1.8 2001/02/04 13:33:54 michael Exp $
#



require "xmlrpc/GServer"

class HttpServer < GServer

  def http_error(status, message, io)
    io.print "HTTP/1.0 #{status} #{message}\r\n"
    io.print "Connection: close\r\n" 
    io.print "Server: XMLRPC::Server (Ruby #{RUBY_VERSION})\r\n"
    io.print "\r\n"
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
      resp = @handler.call(data) 
      raise if resp.nil? or resp.size <= 0
    rescue Exception => e
      http_error(500, "Internal Server Error", io)
      return
    end
    
    io.print "HTTP/1.0 200 OK\r\n"
    io.print "Connection: close\r\n" 
    io.print "Content-Length: #{resp.size}\r\n" 
    io.print "Content-type: text/xml\r\n"
    io.print "Server: XMLRPC::Server (Ruby #{RUBY_VERSION})\r\n"
    io.print "\r\n"
    io.print resp

  end


  def initialize(handler, port = 8080, host = DEFAULT_HOST, maxConnections = 4, 
                 stdlog = $stdout, audit = true, debug = true)
    @handler = handler
    super(port, host, maxConnections, stdlog, audit, debug)
  end

end


