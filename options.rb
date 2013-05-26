require 'optparse'
require 'logger'

module Greylisting
  class Options
    attr_accessor :whitelist_directory, :greylist_directory, :opt_in_directory
    attr_accessor :socket, :pidfile, :daemonize
    attr_accessor :logfile, :loglevel
    attr_accessor :delay, :max_age

    def initialize(argv)
      OptionParser.new(argv) do |opts|
        @opts = opts
        # Set a banner, displayed at the top
        opts.banner = "Usage: greylist.rb [options] <start|stop>"
      
        self.whitelist_directory = '/srv/mail/greylist/whitelist/'
        opts.on( '-w', '--whitelist DIRECTORY', 'Directory to store the whitelist in' ) do |path|
          self.whitelist_directory = path
        end
      
        self.greylist_directory = '/var/spool/exim/greylist/'
        opts.on( '-g', '--greylist DIRECTORY', 'Directory to store the greylist in' ) do |path|
          self.greylist_directory = path
        end
      
        self.opt_in_directory = '/srv/mail/greylist/opt-in/'
        opts.on( '-o', '--optin DIRECTORY', 'Directory where the opt in entries are located' ) do |path|
          self.opt_in_directory = path
        end
      
        self.delay = 5
        opts.on( '-d', '--delay MINUTES', 'Time in minutes after which retries become successful' ) do |value|
          self.delay = value
        end
        
        self.max_age = 10080
        opts.on( '-a', '--max-age MINUTES', 'Time in minutes until which retry must have happened' ) do |value|
          self.max_age = value
        end
        
        self.socket = '/var/run/greylist/greylist.sock'
        opts.on( '-s' , '--socket FILE', 'Socket file') do |file|
          self.socket = file
        end

        self.pidfile = '/var/run/greylist/greylist.pid'
        opts.on( '-p' , '--pid FILE', 'PID file') do |file|
          self.pidfile = file
        end

        self.logfile = '/var/log/greylist/greylist.log'
        opts.on( '-l', '--logfile FILE', 'Logfile' ) do |file|
          self.logfile = file
        end
      
        self.loglevel = Logger::INFO
        opts.on( '-v', '--verbose', 'Log debugging information' ) do
          self.loglevel = Logger::DEBUG
        end

        self.daemonize = true
        opts.on( '-D', '--no-daemon', 'Do not start as daemon' ) do
          self.daemonize = false
        end
      
        # This displays the help screen, all programs are
        # assumed to have this option.
        opts.on( '-h', '--help', 'Display this screen' ) do
          puts opts
          exit
        end
      end.parse!      
    end

    def help
      @opts.help
    end
  end
end

