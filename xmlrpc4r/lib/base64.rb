#
# Data-type Base64 which is supported by XML-RPC but has no direct equivialent in Ruby.
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: base64.rb,v 1.1 2001/01/26 14:28:07 michael Exp $ 
#


module XMLRPC

class Base64
  
  def initialize(str, state = :dec)
    case state
    when :enc
      @str = Base64.decode(str)
    when :dec
      @str = str
    else
      raise "wrong argument; either :enc or :dec"
    end
  end
  
 
  def encoded
    Base64.encode(@str)
  end

  def decoded
    @str  
  end
 

  def Base64.decode(str)
    str.unpack("m")[0]
  end

  def Base64.encode(str)
    [str].pack("m")
  end

end


end # module XMLRPC

