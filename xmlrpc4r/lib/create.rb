#
# Creates XML-RPC call/response documents
# 
# Copyright (C) 2001 by Michael Neumann (neumann@s-direktnet.de)
#
# $Id: create.rb,v 1.18 2001/05/15 19:04:34 michael Exp $
#

require "date"
require "xmlrpc/base64"

module XMLRPC

  module XMLWriter

    class Abstract
      def ele(name, *children)
	element(name, nil, *children)
      end

      def tag(name, txt)
	element(name, nil, text(txt))
      end
    end


    class Simple < Abstract

      def document_to_str(doc)
	doc
      end

      def document(*params)
	params.join("")
      end

      def pi(name, *params)
	"<?#{name} " + params.join(" ") + " ?>"
      end

      def element(name, attrs, *children)
	raise "attributes not yet implemented" unless attrs.nil?
	"<#{name}>" + children.join("") + "</#{name}>"
      end

      def text(txt)
        cleaned = txt.dup
        cleaned.gsub!(/&/, '&amp;')
        cleaned.gsub!(/</, '&lt;')
        cleaned.gsub!(/>/, '&gt;')
        cleaned
      end

    end # class Simple


    class XMLParser < Abstract

      def initialize
	require "xmltreebuilder"
      end

      def document_to_str(doc)
	doc.to_s
      end

      def document(*params)
	XML::SimpleTree::Document.new(*params) 
      end

      def pi(name, *params)
	XML::SimpleTree::ProcessingInstruction.new(name, *params)
      end

      def element(name, attrs, *children)
	XML::SimpleTree::Element.new(name, attrs, *children)
      end

      def text(txt)
	XML::SimpleTree::Text.new(txt)
      end

    end # class XMLParser


    DEFAULT_WRITER = Simple

  end # module XMLWriter

  class Create

    def initialize(xml_writer = XMLWriter::DEFAULT_WRITER.new)
      @writer = xml_writer
    end


    def methodCall(name, *params)
      name = name.to_s

      if name !~ /[a-zA-Z0-9_.:\/]+/
	raise ArgumentError, "Wrong XML-RPC method-name"
      end

      parameter = params.collect do |param|
	@writer.ele("param", conv2value(param))
      end

      if not parameter.empty? then
	parameter = [@writer.ele("params", *parameter)]
      end

	
      tree = @writer.document(
	       @writer.pi("xml", 'version="1.0"'),
	       @writer.ele("methodCall",   
		 @writer.tag("methodName", name),
		 *parameter    # is nothing when == []
	       )
	     )

      @writer.document_to_str(tree) + "\n"
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
	  @writer.ele("param", conv2value(param))
	end
     
	resp = [@writer.ele("params", *resp)]
      else
	if params.size != 1 or params[0] === XMLRPC::FaultException 
	  raise ArgumentError, "no valid fault-structure given"
	end
	resp = @writer.ele("fault", conv2value(params[0].to_h))
      end

	
      tree = @writer.document(
	       @writer.pi("xml", 'version="1.0"'),
	       @writer.ele("methodResponse", resp) 
	     )

      @writer.document_to_str(tree) + "\n"
    end



    #####################################
    private
    #####################################

    #
    # converts a Ruby object into
    # a XML-RPC <value> tag
    #
    def conv2value(param)

	val = case param
	when Fixnum 
	  @writer.tag("i4", param.to_s)

	when Bignum
	  if param >= -(2**31) and param <= (2**31-1)
	    @writer.tag("i4", param.to_s)
	  else
	    raise "Bignum is too big! Must be signed 32-bit integer!"
	  end

	when TrueClass, FalseClass
	  @writer.tag("boolean", param ? "1" : "0")

	when String 
	  @writer.tag("string", param)

	when Float
	  @writer.tag("double", param.to_s)

	when Struct
	  h = param.members.collect do |key| 
	    value = param[key]
	    @writer.ele("member", 
	      @writer.tag("name", key.to_s),
	      conv2value(value) 
	    )
	  end

	  @writer.ele("struct", *h) 

	when Hash
	  # TODO: can a Hash be empty?
	  
	  h = param.collect do |key, value|
	    @writer.ele("member", 
	      @writer.tag("name", key.to_s),
	      conv2value(value) 
	    )
	  end

	  @writer.ele("struct", *h) 

	when Array
	  # TODO: can an Array be empty?
	  a = param.collect {|v| conv2value(v) }
	  
	  @writer.ele("array", 
	    @writer.ele("data", *a)
	  )

	when Date
	  t = param
	  @writer.tag("dateTime.iso8601", 
	    format("%.4d%02d%02dT00:00:00", t.year, t.month, t.day))

	when Time
	  @writer.tag("dateTime.iso8601", param.strftime("%Y%m%dT%H:%M:%S"))  

	when XMLRPC::DateTime
	  @writer.tag("dateTime.iso8601", 
	    format("%.4d%02d%02dT%02d:%02d:%02d", *param.to_a))
   
	when XMLRPC::Base64
	  @writer.tag("base64", param.encoded) 

	else 
	  raise "Wrong type: not yet working!"
	end
	 
	@writer.ele("value", val)
    end

  end # class Create

end # module XMLRPC

