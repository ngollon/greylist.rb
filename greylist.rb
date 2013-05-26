#!/usr/bin/ruby

require './options.rb'
require './daemon.rb'


options = Greylisting::Options.new(ARGV)
abort options.help unless ARGV.count == 1 and (ARGV[0] == 'start' || ARGV[0] == 'stop')

daemon = Greylisting::Daemon.new(options)
Greylisting::Logging.configure(options.logfile, options.loglevel)

if ARGV[0] == 'start'
  daemon.start
end

if ARGV[0] == 'stop'
  daemon.stop  
end

