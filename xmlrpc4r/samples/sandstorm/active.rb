#
# Client-interface wrapper for Sand-Storm component architecture
# (sandstorm.sourceforge.net)
#
# $Id: active.rb,v 1.1 2001/06/25 11:39:04 michael Exp $
#

require "xmlrpc/client"

module Active

  class Client

    def initialize
      @server   = ENV['ACTIVE_REGISTRY_HOST'] || 'localhost'
      @port     = ENV['ACTIVE_REGISTRY_PORT'] || 1422
      @uri      = ENV['ACTIVE_REGISTRY_URI']  || '/RPC2' 

      @active   = XMLRPC::Client.new(@server, @uri, @port.to_i)
      @registry = @active.proxy("active.registry")
    end

    def getComponent(comp)
      info = @registry.getComponent(comp)
      XMLRPC::Client.new(info['host'], info['uri'], info['port']).proxy(comp)
    end

    def getComponents
      @registry.getComponents
    end

    def getComponentInfo(comp)
      @registry.getComponent(comp)
    end

  end # class Client

end # module Active

