#! /usr/bin/env ruby
#
# TCP Tunnel
# Copyright (c) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: tcptunnelgui.rb,v 1.5 2001/07/04 15:28:06 michael Exp $
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

def forward(from, to, str, str2)
  Thread.new {
    while (ln = from.recv(REC_BUF_SZ)) != ""
      str2 << ln
      str.insert("end", ln.gsub("\r", ""))
      to.write ln
    end
    from.close_read
    to.close_write
  }
end

root = TkRoot.new { title "TCP Tunnel/Monitor: Tunneling #{LISTENHOST}:#{LISTENPORT} to #{TUNNELHOST}:#{TUNNELPORT}" }

top    = TkFrame.new(root)
bottom2 = TkFrame.new(root)


top.pack 'side' => 'top', 'fill' => 'x'
bottom2.pack 'side' => 'bottom', 'fill' => 'both'  

bottom3 = TkFrame.new(bottom2)
bottom  = TkFrame.new(bottom2)

bottom.pack 'side' => 'top', 'fill' => 'both'
bottom3.pack 'side' => 'bottom', 'fill' => 'x'  

bot_label = TkLabel.new(bottom3) { text "Listening for connections on port #{LISTENPORT} for host #{LISTENHOST}" }
bot_label.pack

llabel = TkLabel.new(top) { text "From #{LISTENHOST}:#{LISTENPORT}" }
rlabel = TkLabel.new(top) { text "From #{TUNNELHOST}:#{TUNNELPORT}  " }
rlabel.pack 'side' => 'right'
llabel.pack 'side' => 'left' 
TkButton.new(top) {
  text "Clear"
  command { $clear = true }
  pack
}

ltext  = TkText.new(bottom, 'width' => WIDTH, 'height' => HEIGHT) 
rtext  = TkText.new(bottom, 'width' => WIDTH, 'height' => HEIGHT)

ltext.pack 'side' => 'left',  'fill' => 'y'
rtext.pack 'side' => 'right', 'fill' => 'y'

sc = ""
ss = ""


Thread.new {
  Tk.mainloop
  exit
}

Thread.new {
  loop {
    if $clear 
      ltext.value = ""
      rtext.value = "" 
      sc = ""
      ss = ""
      $clear = false
    end
  }
}

s = TCPServer.new(LISTENHOST, LISTENPORT)
while client = s.accept
  server = TCPSocket.new(TUNNELHOST, TUNNELPORT)

  lc = ""
  ls = ""

  a = forward(client, server, ltext, lc)
  b = forward(server, client, rtext, ls)
  a.join; b.join

  sc += lc + "\n\n" 
  ss += ls + "\n\n"
  ltext.value = sc.gsub("\r", "") 
  rtext.value = ss.gsub("\r", "") 

  puts lc
  puts "-" * 79
  puts ls
  puts "-" * 79
end

