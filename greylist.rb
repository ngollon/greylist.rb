#!/usr/bin/ruby

require '/etc/greylist.rb/config.rb'
require_relative 'daemon.rb'

abort "Usage greylist.rb <start|stop>" unless ARGV.count == 1 and (ARGV[0] == 'start' || ARGV[0] == 'stop')

daemon = Greylist::Daemon.new(Greylist::Config)
Greylist::Logging.configure(Greylist::Config.logfile, Greylist::Config.loglevel)

if ARGV[0] == 'start'
  daemon.start
end

if ARGV[0] == 'stop'
  daemon.stop  
end

