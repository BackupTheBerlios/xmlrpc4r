#! /usr/bin/env ruby

#
# Parser for XML-RPC call and response
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: parser.rb,v 1.4 2001/01/26 14:56:40 michael Exp $
#


require "xmltreebuilder"
require "xmlrpc/base64.rb"

module XMLRPC

class Parser

  public

  def parseMethodResponse(str)
    methodResponse_document(createCleanedTree(str))
  end

  def parseMethodCall(str)
    methodCall_document(createCleanedTree(str))
  end



  private

  #
  # remove all whitespace but the innerst 
  # (could be e.g. a string!), and all comments
  #
  def removeWhitespacesAndComments(node)
    remove = []
    childs = node.childNodes.to_a
    childs.each do |nd|
      case nd.nodeType
      when XML::SimpleTree::Node::TEXT
	if nd.nodeValue.strip == "" and childs.size != 1
	   remove << nd
	end
      when XML::SimpleTree::Node::COMMENT
	remove << nd
      else
	removeWhitespacesAndComments(nd)
      end 
    end

    remove.each { |i| node.removeChild(i) }
  end

   
  def nodeMustBe(node, name)
    cmp = case name
    when Array 
      name.include?(node.nodeName)
    when String
      name == node.nodeName
    else
      raise "error"
    end  

    if not cmp then
      raise "wrong xml-rpc (name)"
    end

    node
  end

  #
  # returns, when successfully the only child-node
  #
  def hasOnlyOneChild(node, name=nil)
    if node.childNodes.to_a.size != 1
      raise "wrong xml-rpc (size)"
    end
    if name != nil then
      nodeMustBe(node.firstChild, name)
    end
  end


  def assert(b)
    if not b then
      raise "assert-fail" 
    end
  end

  ################


  def text(node)
    assert( node.nodeType == XML::SimpleTree::Node::TEXT )
    assert( node.hasChildNodes == false )
    assert( node.nodeValue != nil )

    node.nodeValue.to_s
  end


  def integer(node)
    #TODO: check string for float because to_i returnsa
    #      0 when wrong string
     nodeMustBe(node, %w(i4 int))    
    hasOnlyOneChild(node)
    
    text(node.firstChild).to_i
  end

  def boolean(node)
    nodeMustBe(node, "boolean")    
    hasOnlyOneChild(node)
    
    case text(node.firstChild)
    when "0" then false
    when "1" then true
    else
      raise "RPC-value of type boolean is wrong" 
    end
  end

  def string(node)
    nodeMustBe(node, "string")    
    hasOnlyOneChild(node)
    
    text(node.firstChild)
  end

  def double(node)
    #TODO: check string for float because to_f returnsa
    #      0.0 when wrong string
    nodeMustBe(node, "double")    
    hasOnlyOneChild(node)
    
    text(node.firstChild).to_f
  end

  def dateTime(node)
    raise "not yet implemented"
  end

  def base64(node)
    nodeMustBe(node, "base64")
    hasOnlyOneChild(node)
     
    XMLRPC::Base64.new(text(node.firstChild), :enc)
  end

  def struct(node)
    nodeMustBe(node, "struct")    
    
    hash = {}
    node.childNodes do |me|
      n, v = member(me)  
      hash[n] = v
    end 
    hash
  end

  def member(node)
    nodeMustBe(node, "member")
    assert( node.childNodes.to_a.size == 2 ) 

    [ name(node[0]), value(node[1]) ]
  end

  def name(node)
    nodeMustBe(node, "name")
    hasOnlyOneChild(node)
    text(node.firstChild) 
  end

  def array(node)
    nodeMustBe(node, "array")
    hasOnlyOneChild(node, "data") 
    data(node.firstChild)  
  end

  def data(node)
    nodeMustBe(node, "data")

    node.childNodes.to_a.collect do |val|
      value(val)
    end 
  end

  def value(node)
    nodeMustBe(node, "value")
    hasOnlyOneChild(node) 

    child = node.firstChild
    
    case child.nodeType
    when XML::SimpleTree::Node::TEXT
      text(child)
    when XML::SimpleTree::Node::ELEMENT
      case child.nodeName
      when "i4", "int"        then integer(child)
      when "boolean"          then boolean(child)
      when "string"           then string(child)
      when "double"           then double(child)
      when "dateTime.iso8601" then dateTime(child)
      when "base64"           then base64(child)
      when "struct"           then struct(child)
      when "array"            then array(child) 
      else 
	raise "wrong/unknown XML-RPC type"
      end
    else
      raise "wrong type of node"
    end

  end

  def param(node)
    nodeMustBe(node, "param")
    hasOnlyOneChild(node, "value")
    value(node.firstChild) 
  end
   
  def methodResponse_document(node)
    assert( node.nodeType == XML::SimpleTree::Node::DOCUMENT )
    hasOnlyOneChild(node, "methodResponse")
    
    methodResponse(node.firstChild)
  end

  def methodCall_document(node)
    assert( node.nodeType == XML::SimpleTree::Node::DOCUMENT )
    hasOnlyOneChild(node, "methodCall")
    
    methodCall(node.firstChild)
  end


  def methodResponse(node)
    nodeMustBe(node, "methodResponse")
    hasOnlyOneChild(node, %w(params fault))
    child = node.firstChild

    case child.nodeName
    when "params"
      [ true, params(child) ] 
    when "fault"
      [ false, fault(child) ]
    else
      raise "unexpected error"
    end

  end

  def methodCall(node)
    nodeMustBe(node, "methodCall")
    assert( node.childNodes.to_a.size == 2 ) 

    [ methodName(node[0]), params(node[1]) ]  
  end

  def methodName(node)
    nodeMustBe(node, "methodName")
    hasOnlyOneChild(node)
    text(node.firstChild) 
  end


  def params(node)
    nodeMustBe(node, "params")

    node.childNodes.to_a.collect do |n|
      param(n)
    end
  end


  def fault(node)
    # TODO: fault do not proof if the value is a structure etc...
    nodeMustBe(node, "fault")
    hasOnlyOneChild(node, "value")
    value(node.firstChild) 
  end



  def createCleanedTree(str)
    doc = XML::SimpleTreeBuilder.new.parse(str)
    doc.documentElement.normalize
    removeWhitespacesAndComments(doc)
    doc
  end

end # class Parser

end # module XMLRPC

