require 'socket'
require './directory_based_list'

module Greylisting
  class Daemon
    def initialize(options)
      @options = options
    end

    def run
      socket_path = @options.socket
      File.unlink(socket_path) if File.exists?(socket_path) && File.socket?(socket_path)

      server = UNIXServer.new(socket_path)

      whitelist = DirectoryBasedList.new(@options.whitelist_directory)
      greylist = DirectoryBasedList.new(@options.greylist_directory)
      optinlist = DirectoryBasedList.new(@options.opt_in_directory)

      while (socket = server.accept)        
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
        socket.close
      end
    end
  end
end

