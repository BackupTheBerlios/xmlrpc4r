# Copyright (C) 2001 John W. Small All Rights Reserved
# mailto:jsmall@laser.net  subject:ruby-generic-server
# Freeware

require "socket"
require "thread"

class Server

  def serve(io)
  end

  @@services = {}   # Hash of opened ports, i.e. services
  @@servicesMutex = Mutex.new

  def Server.stop(port)
    @@servicesMutex.synchronize { @@services[port].stop }
  end

  def Server.in_service?(port)
    @@services.has_key?(port)
  end

  def stop
    @connectionsMutex.synchronize  {
      if @tcpServerThread
        @tcpServerThread.raise "stop"
      end
    }
  end

  def stopped?
    @tcpServerThread == nil
  end

  def shutdown
    @shutdown = true
  end

  def connections
    @connections.size
  end

  def join
    @tcpServerThread.join if @tcpServerThread
  end

  attr_reader :port, :maxConnections
  attr_accessor :stdlog, :audit, :debug

  def connecting(client)
    addr = client.peeraddr
    log("#{self.class.to_s}:#{@port} client:#{addr[1]} " +
        "#{addr[2]}<#{addr[3]}> connect")
    true
  end

  def disconnecting(clientPort)
    log("#{self.class.to_s} #{@port} " +
      "client:#{clientPort} disconnect")
  end

  protected :connecting, :disconnecting

  def starting()
    log("#{self.class.to_s} #{@port} start")
  end

  def stopping()
    log("#{self.class.to_s} #{@port} stop")
  end

  protected :starting, :stopping

  def error(detail)
    log($!+msg.backtrace.join("\n"))
  end

  def log(msg)
    if @stdlog
      @stdlog.puts("[#{Time.new.ctime}] %s" % msg)
      @stdlog.flush
    end
  end

  protected :error, :log

  def initialize(port, maxConnections = 4,
    stdlog = $stdout, audit = false, debug = false)
    @tcpServerThread = nil
    @port = port
    @maxConnections = maxConnections
    @connections = []
    @connectionsMutex = Mutex.new
    @connectionsCV = ConditionVariable.new
    @stdlog = stdlog
    @audit = audit
    @debug = debug
  end

  def start(maxConnections = -1)
    raise "running" if !stopped?
    @shutdown = false
    @maxConnections = maxConnections if maxConnections > 0
    @@servicesMutex.synchronize  {
      if Server.in_service?(@port)
        raise "Port already in use: #{@port}!"
      end
      @tcpServer = TCPServer.new(@port)
      @port = @tcpServer.addr[1]
      @@services[@port] = self;
    }
    @tcpServerThread = Thread.new {
      begin
        starting if @audit
        while !@shutdown
          @connectionsMutex.synchronize  {
             while @connections.size >= @maxConnections
               @connectionsCV.wait(@connectionsMutex)
             end
          }
          client = @tcpServer.accept
          @connections << Thread.new(client)  { |myClient|
            begin
              myPort = myClient.peeraddr[1]
              serve(myClient) if !@audit or connecting(myClient)
            rescue => detail
              error(detail) if @debug
            ensure
              begin
                myClient.close
              rescue
              end
              @connectionsMutex.synchronize {
                @connections.delete(Thread.current)
                @connectionsCV.signal
              }
              disconnecting(myPort) if @audit
            end
          }
        end
      rescue => detail
        error(detail) if @debug
      ensure
        begin
          @tcpServer.close
        rescue
        end
        if @shutdown
          @connectionsMutex.synchronize  {
             while @connections.size > 0
               @connectionsCV.wait(@connectionsMutex)
             end
          }
        else
          @connections.each { |c| c.raise "stop" }
        end
        @tcpServerThread = nil
        @@servicesMutex.synchronize  {
          @@services.delete(@port)
        }
        stopping if @audit
      end
    }
    self
  end

end
