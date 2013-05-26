require 'socket'
require './directory_based_list.rb'
require './logging.rb'

module Greylisting
  class Daemon
    include Logging

    def initialize(options)
      @options = options
    end

    def start
      abort "Daemon already running. Check the pidfile at #{@options.pidfile}" if File.exists?(@options.pidfile)

      # Check options
      abort "Whitelist directory #{@options.whitelist_directory} does not exist or is not writabable" unless File.exists?(@options.whitelist_directory) and File.writable?(@options.whitelist_directory)

      abort "Greylist directory #{@options.greylist_directory} does not exist or is not writable" unless File.exists?(@options.greylist_directory) and File.writable?(@options.greylist_directory)

      abort "Opt-in directory #{@options.opt_in_directory} does not exist" unless File.exists?(@options.opt_in_directory)

      logger.info("Initializing Greylist.rb, version 0.1")
      logger.info("Whitelist directory: #{@options.whitelist_directory}")
      logger.info("Greylist directory: #{@options.greylist_directory}")
      logger.info("Opt-in directory: #{@options.opt_in_directory}")      

      Process.daemon if @options.daemonize

      File.write(@options.pidfile, Process.pid)
    
      logger.info("Process ID: #{Process.pid}")

      self.run
    end

    def stop
      abort "No running process found" if not File.exists?(@options.pidfile)
      pid = File.read(@options.pidfile)
      logger.info("Stopping Daemon with process id: #{pid}")
      begin
        File.unlink(@options.pidfile)
        File.unlink(@options.socket)
        Process.kill(9, Integer(pid))
      rescue Exception => msg
        logger.error("Process probably not running, message: #{msg}")
      end     
    end

    def run
      socket_path = @options.socket
      File.unlink(socket_path) if File.exists?(socket_path) && File.socket?(socket_path)

      server = UNIXServer.new(socket_path)

      whitelist = DirectoryBasedList.new(@options.whitelist_directory)
      greylist = DirectoryBasedList.new(@options.greylist_directory)
      optinlist = DirectoryBasedList.new(@options.opt_in_directory)

      logger.info('Started')     

      while (socket = server.accept)
        begin   # rescue
          input = socket.gets
          sender, destination = input.split
# todo: check inputs
          if not optinlist.contains?(destination)
            socket.print '.Greylisting disabled for destination'
          elsif whitelist.contains?(sender)
            socket.print '.Sender whitelisted'
          else
            if greylist.contains?(sender + destination)
              time_difference = Time.now - greylist.ctime(sender + destination)
              if time_difference > @options.delay * 60
                greylist.remove(sender + destination)
                whitelist.add(sender)
                socket.print ":X-Greylist: Delayed for #{time_difference.round} seconds"
              else
                socket.print '!Greylisted'
              end
            else
              greylist.add(sender + destination)
              socket.print '!Greylisted'
            end
          end
        rescue Exception => msg
          logger.error("Error: #{msg}")
        ensure 
          socket.close
        end
      end
    end
  end
end

