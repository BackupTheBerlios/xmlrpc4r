#
# Creates XML-RPC call/response documents
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: create.rb,v 1.12 2001/01/27 19:52:36 michael Exp $
#

require "date"
require "xmltreebuilder"
require "xmlrpc/base64"

module XMLRPC

class Create

  El = XML::SimpleTree::Element
  Pi = XML::SimpleTree::ProcessingInstruction
  Tx = XML::SimpleTree::Text
  Do = XML::SimpleTree::Document


  def methodCall(name, *params)
    name = name.to_s

    if name !~ /[a-zA-Z0-9_.:\/]+/
      raise ArgumentError, "Wrong XML-RPC method-name"
    end

    parameter = params.collect do |param|
      El.new("param", nil, conv2value(param))
    end

    if not parameter.empty? then
      parameter = [El.new("params", nil, *parameter)]
    end

      
    tree = Do.new(
	     Pi.new("xml", 'version="1.0"'),
	     El.new("methodCall", nil,  
	       El.new("methodName", nil,
		 Tx.new(name)
	       ),
	       *parameter    # is nothing when == []
	     )
	   )

    tree.to_s + "\n"
  end



  #
  # generates a XML-RPC methodResponse document
  #
  # if is_ret == false then the params array must
  # contain only one element, which is a structure
  # of a fault return-value.
  # 
  # if is_ret == true then a normal 
  # return-value of all the given params is created.
  #
  def methodResponse(is_ret, *params)

    if is_ret 
      resp = params.collect do |param|
	El.new("param", nil, conv2value(param))
      end
   
      resp = [El.new("params", nil, *resp)]
    else
      if params.size != 1 or params[0] === XMLRPC::FaultException 
	raise ArgumentError, "no valid fault-structure given"
      end
      resp = El.new("fault", nil, conv2value(params[0].to_h))
    end

      
    tree = Do.new(
	     Pi.new("xml", 'version="1.0"'),
	     El.new("methodResponse", nil, resp) 
	   )

    tree.to_s + "\n"
  end



  #####################################
  private
  #####################################

  def ele(e, txt)
    El.new(e, nil, Tx.new(txt))
  end

  #
  # converts a Ruby object into
  # a XML-RPC <value> tag
  #
  def conv2value(param)

      val = case param
      when Fixnum 
	ele("i4", param.to_s)
      when TrueClass, FalseClass
	ele("boolean", param ? "1" : "0")
      when String 
	ele("string", param)
      when Float
	ele("double", param.to_s)
      when Hash
	# TODO: can a Hash be empty?
	
	h = param.collect do |key, value|
	  El.new("member", nil,
	    ele("name", key.to_s),
	    conv2value(value) 
	  )
	end

	El.new("struct", nil, *h) 
      when Array
	# TODO: can an Array be empty?
	a = param.collect {|v| conv2value(v) }
	
	El.new("array", nil,
	  El.new("data", nil, *a)
	)
      when Date, Time
        # TODO: Time.gm??? .local???
        t = param
        if t.kind_of? Date then
          ele("dateTime.iso8601", 
            format("%.4d%02d%02dT00:00:00", t.year, t.month, t.day))
        else
          ele("dateTime.iso8601", t.strftime("%Y%m%dT%H:%M:%S"))  
        end
      when XMLRPC::Base64
	ele("base64", param.encoded) 
      else 
	raise "Wrong type: not yet working!"
      end
       
      El.new("value", nil, val)
  end


  end


end # module XMLRPC

