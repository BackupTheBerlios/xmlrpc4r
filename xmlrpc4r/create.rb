#! /usr/bin/env ruby

#
# Creates XML-RPC call/response documents
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: create.rb,v 1.2 2001/01/24 19:43:19 michael Exp $
#


require "xmltreebuilder"
require "xmltree"
include XML::SimpleTree


def ele(e, txt)
  Element.new(e, nil, Text.new(txt))
end

#
# converts a Ruby object into
# a XML-RPC <value> tag
#
def conv2value(param)

    # TODO: dateTime.iso8601
    #       base64 ??
 
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
        Element.new("member", nil,
          ele("name", key.to_s),
          conv2value(value) 
        )
      end

      Element.new("struct", nil, *h) 
    when Array
      # TODO: can an Array be empty?
      a = param.collect {|v| conv2value(v) }
      
      Element.new("array", nil,
        Element.new("data", nil, *a)
      )
    else 
      raise "Wrong type: not yet working!"
    end
     
    Element.new("value", nil, val)
end


####################################


def createMethodCall(name, *params)
  # TODO: check method_name

  parameter = params.collect do |param|
    Element.new("param", nil, conv2value(param))
  end

  if not parameter.empty? then
    parameter = [Element.new("params", nil, *parameter)]
  end

    
  tree = Document.new(
           ProcessingInstruction.new("xml", 'version="1.0"'),
           Element.new("methodCall", nil,  
             Element.new("methodName", nil,
               Text.new(name)
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
def createMethodResponse(is_ret, *params)

  if is_ret 
    resp = params.collect do |param|
      Element.new("param", nil, conv2value(param))
    end
 
    resp = [Element.new("params", nil, *resp)]
  else
    if params.size != 1 or params[0] === Hash 
      raise "no valid fault-structure given"
    end
    resp = Element.new("fault", nil, conv2value(params[0]))
  end

    
  tree = Document.new(
           ProcessingInstruction.new("xml", 'version="1.0"'),
           Element.new("methodResponse", nil, resp) 
         )

  tree.to_s + "\n"
end


