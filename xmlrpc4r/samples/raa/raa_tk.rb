#!/usr/bin/env ruby

#
# Tk client for XML-RPC RAA Interface
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: raa_tk.rb,v 1.1 2001/03/22 22:53:36 michael Exp $
#

require "tk"
require "tkscrollbox"
require "raa"


HOST = ARGV.shift || "www.ruby-lang.org"
PATH = ARGV.shift || "/~nahi/xmlrpc/raa/"
PORT = (ARGV.shift || 80).to_i

INDENT = "    "



raa = RAA.new(HOST, PATH, PORT)


root  = TkRoot.new { title "TkRAA " }
lframe = TkFrame.new(root)
rframe = TkFrame.new(root)

def generate_listing(raa)
  l = []
  t = raa.getProductTree
  t.keys.sort.each {|i|
   l << { :text => i, :type => :maj } 
    t[i].keys.sort.each {|j|
      l << { :text => j, :type => :min }
      t[i][j].sort.each {|k|
        l << { :text => k, :type => :entry }
      }
    }
  }

  return l
end

#$list = generate_listing(raa)




list_w = TkScrollbox.new(lframe) {
  relief 'raised'
  pack 'fill' => 'both'
}

#list_w = TkListbox.new(lframe, 'selectmode' => 'single')
#scroll_bar = TkScrollbar.new(lframe, 'command' => proc {|*args| list_w.yview *args})
#scroll_bar.pack('side' => 'left', 'fill' => 'y')
#list_w.yscrollcommand(proc {|first,last| scroll_bar.set(first,last)})
#list_w.pack('side' => 'left', 'fill' => 'y')

=begin
$list.each {|i|
  txt = i[:text]

  list_w.insert('end',
    case i[:type]
    when :maj   then txt
    when :min   then INDENT + txt
    when :entry then (INDENT*2) + txt
    end
  )

}

=end

list_w.bind("ButtonRelease-1") {
  index = list_w.curselection[0].to_i
  p index
  entry = $list[index]
  p entry

  if entry[:type] == :entry then
    info = raa.getInfoFromName(entry[:text])
    $product.keys.each {|k| 
      $product[k].value = info["product"][k.to_s]  
    } 
  end
}


$product = {}
$product[:download]    = TkVariable.new
$product[:status]      = TkVariable.new
$product[:version]     = TkVariable.new
$product[:license]     = TkVariable.new
$product[:name]        = TkVariable.new
$product[:homepage]    = TkVariable.new
$product[:description] = TkVariable.new


def label_entry(parent, label, tkvar, row)
  TkLabel.new(parent) {
    text label
  }.grid('row' => row, 'column' => 0, 'sticky' => 'w')
  
  TkEntry.new(parent) {
    textvariable tkvar
  }.grid('row' => row, 'column' => 1)
end


 
label_entry(rframe, "Download", $product[:download], 0)
label_entry(rframe, "Status", $product[:status], 1)
label_entry(rframe, "Version", $product[:version], 2)
label_entry(rframe, "License", $product[:license], 3)
label_entry(rframe, "Name", $product[:name], 4)
label_entry(rframe, "Homepage", $product[:homepage], 5)
label_entry(rframe, "Description", $product[:description], 6)




lframe.pack 'side' => 'left', 'fill' => 'y', 'fill' => 'x'
rframe.pack 'side' => 'right', 'fill' => 'y'

#Tk.wm "HallO"




Tk.mainloop




=begin

  $msg.configure('text'=>$msg.cget('text') + message)

$entry = TkVariable.new

$msg = TkMessage.new(root) {
  pack
}

TkEntry.new(root) {
  textvariable $entry
  pack
}

TkButton.new(root) {
  text "send"
  command {
    $mutex.synchronize {
      Thread.new {
        chat_server.call("chat.server.send", CHANNEL, $entry.value+"\n")
      }
      $entry.value = "" 
    }
  } 
  pack
}
=end

  
