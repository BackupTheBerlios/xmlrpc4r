#
# Parser for XML-RPC call and response
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: parser.rb,v 1.21 2001/04/20 13:38:02 michael Exp $
#


require "date"
require "xmlrpc/base64"
require "xmlrpc/datetime"

module XMLRPC


  class FaultException < Exception
    attr_reader :faultCode, :faultString

    def initialize(faultCode, faultString)
      @faultCode   = faultCode
      @faultString = faultString
    end
    
    # returns a hash
    def to_h
      {"faultCode" => @faultCode, "faultString" => @faultString}
    end
  end


  module XMLParser

    class XMLParser

      public

      def initialize
        require "xmltreebuilder"
      end

      def parseMethodResponse(str)
	methodResponse_document(createCleanedTree(str))
      end

      def parseMethodCall(str)
	methodCall_document(createCleanedTree(str))
      end



      private

      #
      # remove all whitespaces but in the tags i4, int, boolean....
      # and all comments
      #
      def removeWhitespacesAndComments(node)
	remove = []
	childs = node.childNodes.to_a
	childs.each do |nd|
	  case nd.nodeType
	  when XML::SimpleTree::Node::TEXT
	    unless %w(i4 int boolean string double dateTime.iso8601 base64).include? node.nodeName 
	      remove << nd if nd.nodeValue.strip == "" # and childs.size != 1
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
     
      # the node `node` has empty string or string
      def text_zero_one(node)
	nodes = node.childNodes.to_a.size

	if nodes == 1
	  text(node.firstChild)
	elsif nodes == 0
	  ""
	else
	  raise "wrong xml-rpc (size)"
	end
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
	text_zero_one(node)
      end

      def double(node)
	#TODO: check string for float because to_f returnsa
	#      0.0 when wrong string
	nodeMustBe(node, "double")    
	hasOnlyOneChild(node)
	
	text(node.firstChild).to_f
      end

      def dateTime(node)
	nodeMustBe(node, "dateTime.iso8601")
	hasOnlyOneChild(node)
	
	dt = text(node.firstChild)
	
	if dt =~ /^(-?\d\d\d\d)(\d\d)(\d\d)T(\d\d):(\d\d):(\d\d)$/ then
	  # TODO: Time.gm ??? .local ??? 
	  a = [$1, $2, $3, $4, $5, $6].collect{|i| i.to_i}
	  
	  XMLRPC::DateTime.new(*a)
	  #if a[0] >= 1970 then
	  #  Time.gm(*a)
	  #else
	  #  Date.new(*a[0,3])
	  #end
	else
	  raise "wrong dateTime.iso8601 format"
	end
      end

      def base64(node)
	nodeMustBe(node, "base64")
	#hasOnlyOneChild(node)
	 
	XMLRPC::Base64.new(text_zero_one(node), :enc)
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
	#hasOnlyOneChild(node)
	text_zero_one(node) 
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
	  [ true, params(child,false) ] 
	when "fault"
	  [ false, fault(child) ]
	else
	  raise "unexpected error"
	end

      end

      def methodCall(node)
	nodeMustBe(node, "methodCall")
	assert( (1..2).include? node.childNodes.to_a.size ) 
	name = methodName(node[0])

	if node.childNodes.to_a.size == 2 then
	  pa = params(node[1])
	else # no parameters given
	  pa = []
	end
	[name, pa]
      end

      def methodName(node)
	nodeMustBe(node, "methodName")
	hasOnlyOneChild(node)
	text(node.firstChild) 
      end

      def params(node, call=true)
	nodeMustBe(node, "params")

	if call 
	  node.childNodes.to_a.collect do |n|
	    param(n)
	  end
	else # response (only one param)
	  hasOnlyOneChild(node)
	  param(node.firstChild)
	end
      end


      def fault(node)
	nodeMustBe(node, "fault")
	hasOnlyOneChild(node, "value")
	f = value(node.firstChild) 
	assert( f.kind_of? Hash )
	assert( f.size == 2 )
	assert( f.has_key? "faultCode" )
	assert( f.has_key? "faultString" )
	assert( f["faultCode"].kind_of? Fixnum )
	assert( f["faultString"].kind_of? String )

	XMLRPC::FaultException.new(f["faultCode"], f["faultString"]) 
      end

      def createCleanedTree(str)
	doc = XML::SimpleTreeBuilder.new.parse(str)
	doc.documentElement.normalize
	removeWhitespacesAndComments(doc)
	doc
      end

    end # class XMLParser

    DEFAULT_PARSER = XMLParser

  end # module XMLParser



end # module XMLRPC

