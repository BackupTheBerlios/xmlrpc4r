#! /usr/bin/env ruby
#
# TCP Tunnel
# Copyright (c) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: tcptunnelgui.rb,v 1.1 2001/07/04 10:26:05 michael Exp $
# 

require "socket"
require "tk"

unless ARGV.size == 2
  puts "USAGE: #$0 listen tunnel"
  puts "  e.g. #$0 localhost:8070 localhost:8080"
  exit 1
end

LISTENHOST, LISTENPORT = ARGV.shift.split(":")
TUNNELHOST, TUNNELPORT = ARGV.shift.split(":")


REC_BUF_SZ = 100
WIDTH  = 50
HEIGHT = 35

def forward(from, to, str)
  Thread.new {
    while (ln = from.recv(REC_BUF_SZ)) != ""
      str.insert("end", ln.gsub("\r", ""))
      to.write ln
    end
    from.close_read
    to.close_write
  }
end

root = TkRoot.new { title "Ruby TcpTunnel" }

top    = TkFrame.new(root)
bottom = TkFrame.new(root)

top.pack 'side' => 'top', 'fill' => 'x'
bottom.pack 'side' => 'bottom', 'fill' => 'both'  

llabel = TkLabel.new(top) { text "From #{LISTENHOST}:#{LISTENPORT}" }
rlabel = TkLabel.new(top) { text "To #{TUNNELHOST}:#{TUNNELPORT}  " }
rlabel.pack 'side' => 'right'
llabel.pack 'side' => 'left' 
TkButton.new(top) {
  text "Refresh"
  command { $refresh = true }
  pack
}

ltext  = TkText.new(bottom, 'width' => WIDTH, 'height' => HEIGHT) 
rtext  = TkText.new(bottom, 'width' => WIDTH, 'height' => HEIGHT)

ltext.pack 'side' => 'left',  'fill' => 'y'
rtext.pack 'side' => 'right', 'fill' => 'y'



Thread.new {
  Tk.mainloop
  exit
}

Thread.new {
  loop {
    if $refresh 
      ltext.value = ""
      rtext.value = "" 
      $refresh = false
    end
  }
}


s = TCPServer.new(LISTENHOST, LISTENPORT)
while client = s.accept
  server = TCPSocket.new(TUNNELHOST, TUNNELPORT)

  a = forward(client, server, ltext)
  b = forward(server, client, rtext)

  a.join; b.join
end

