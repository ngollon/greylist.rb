require 'socket'
require_relative 'directory_based_list.rb'
require_relative 'logging.rb'

module Greylist
  class Daemon
    include Logging

    def initialize(config)
      @config = config
    end

    def start
      abort "Daemon already running. Check the pidfile at #{@config.pidfile}" if File.exists?(@config.pidfile)

      # Check config
      abort "Whitelist directory #{@config.whitelist_directory} does not exist or is not writabable" unless File.exists?(@config.whitelist_directory) and File.writable?(@config.whitelist_directory)

      abort "Greylist directory #{@config.greylist_directory} does not exist or is not writable" unless File.exists?(@config.greylist_directory) and File.writable?(@config.greylist_directory)

      abort "Opt-in directory #{@config.opt_in_directory} does not exist" unless File.exists?(@config.opt_in_directory)

      logger.info("Initializing Greylist.rb, version 0.1")
      logger.info("Whitelist directory: #{@config.whitelist_directory}")
      logger.info("Greylist directory: #{@config.greylist_directory}")
      logger.info("Opt-in directory: #{@config.opt_in_directory}")      

      Process.daemon
      File.open(@config.pidfile, 'w') { |file| file.write(Process.pid) }
    
      logger.info("Process ID: #{Process.pid}")

      self.run
    end

    def stop
      abort "No running process found" if not File.exists?(@config.pidfile)
      pid = File.read(@config.pidfile)
      logger.info("Stopping Daemon with process id: #{pid}")
      begin
        File.unlink(@config.pidfile)
        File.unlink(@config.socketfile)
        Process.kill(9, Integer(pid))
      rescue Exception => msg
        logger.error("Process probably not running, message: #{msg}")
      end     
    end

    def run
      File.unlink(@config.socketfile) if File.exists?(@config.socketfile) && File.socket?(@config.socketfile)

      server = UNIXServer.new(@config.socketfile)

      whitelist = DirectoryBasedList.new(@config.whitelist_directory)
      greylist = DirectoryBasedList.new(@config.greylist_directory)
      optinlist = DirectoryBasedList.new(@config.opt_in_directory)

      logger.info('Started')     

      while (socket = server.accept)
        begin   # rescue          
          input = socket.gets
          logger.info("Incomming request: #{input.chop}")          # chopping here removes the newline
          sender, destination = input.split
# todo: check inputs
          if not optinlist.contains?(destination)
            logger.info("Greylisting disabled for #{destination}")
            socket.print '.Greylisting disabled for destination'
          elsif whitelist.contains?(sender)
            logger.info("Sender #{sender} whitelisted ")
            socket.print '.Sender whitelisted'
          else
            if greylist.contains?(sender + destination)
              time_difference = Time.now - greylist.ctime(sender + destination)
              if time_difference > @config.greylisting_delay * 60
                logger.info("Retry for message from #{sender} to #{destination} successful.")
                greylist.remove(sender + destination)
                logger.info("Adding #{sender} to whitelist.")
                whitelist.add(sender)
                socket.print ":X-Greylist: Delayed for #{time_difference.round} seconds"
              else
                logger.info("Retry for message from #{sender} to #{destination} too early after only #{time_difference.round} seconds.")
                socket.print '!Greylisted'
              end
            else
              logger.info("Greylisted message from #{sender} to #{destination}")
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

