#!/usr/bin/ruby

require './options.rb'
require './directory_based_list.rb'
require './daemon.rb'


options = Greylisting::Options.new(ARGV)
abort options.help unless ARGV.count == 1 and (ARGV[0] == 'start' || ARGV[0] == 'stop')

if ARGV[0] == 'stop'
  abort "No running process found" if not File.exists?(options.pidfile)
  pid = File.read(options.pidfile)
  Process.kill(9, Integer(pid))
  File.unlink(options.pidfile)
  File.unlink(options.socket)
  exit
end

if ARGV[0] == 'start'
  abort "Daemon already running. Check the pidfile at #{options.pidfile}" if File.exists?(options.pidfile)

# Check options
  abort "Whitelist directory #{options.whitelist_directory} does not exist or is not writable" \
      unless File.exists?(options.whitelist_directory) and File.writable?(options.whitelist_directory)
  
  abort "Greylist directory #{options.greylist_directory} does not exist or is not writable" \
      unless File.exists?(options.greylist_directory) and File.writable?(options.greylist_directory)
 
  abort "Opt-in directory #{options.opt_in_directory} does not exist" \
      unless File.exists?(options.opt_in_directory)
 
  Process.daemon if options.daemonize
  
  File.write(options.pidfile, Process.pid)

  Greylisting::Daemon.new(options).run
end

