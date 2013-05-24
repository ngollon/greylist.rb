#!/usr/bin/ruby

require 'optparse'

def verbose(message)
  puts message if $options[:verbose]
end

$options = {}

# These are not yet configurable
$options[:whitelist] = '/srv/mail/greylisting/whitelist/'
$options[:optin] = '/srv/mail/greylisting/opt-in/'
$options[:greylist] = '/var/spool/exim/greylisting/greylist/'
$options[:delay] = 5 # minutes
$options[:max_age] = 10080 # minutes

OptionParser.new do|opts|
  # Set a banner, displayed at the top
  opts.banner = "Usage: greylist.rb [options] -a <ip sender> -r <user>"

  $options[:clean] = false
  opts.on( '-c', '--clean', 'Clean old messages from greylist database' ) do 
    $options[:clean] = true
  end

  $options[:sender] = nil
  opts.on( '-s', '--sender ADDRESS', 'Sender IP address' ) do |sender|
    $options[:sender] = sender
  end

  $options[:user] = nil
  opts.on( '-u', '--user NAME', 'Recipient name' ) do |name|
    $options[:user] = name
  end

  $options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    $options[:verbose] = true
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!

if $options[:clean]
  verbose("Cleaning greylist database")
  Dir::foreach($options[:greylist]) do |filename|
    next if filename == '.' or filename == '..'
    greyfile = $options[:greylist] + filename
    if File::ctime(greyfile) + 60 * $options[:max_age] < Time::now      
      verbose("-- deleting #{filename}: too old")
      `rm #{greyfile}`
    end  
  end
  exit
end

abort 'Specify a sender address.' if $options[:sender].nil?
abort 'Specify a user.' if $options[:user].nil?

whitefile = $options[:whitelist] + $options[:sender]
greyfile = $options[:greylist] + $options[:user] + $options[:sender]
optinfile = $options[:optin] + $options[:user]

# Check if the user opted into greylisting
if not File::exists?(optinfile)
  exit
end

# Check if sender is already whitelisted
verbose("Checking if #{$options[:sender]} is already whitelisted...")
if File::exists?(whitefile)
  verbose('-- whitelisted')
  `rm #{greyfile}` if File::exists?(greyfile)
  exit
end
verbose('-- not whitelisted')

# Check if there already is an greylist entry
verbose("Checking if a message from #{$options[:sender]} to #{$options[:user]} is already greylisted...")
if File::exists?(greyfile)
  verbose("-- yes, checking if it waited long enough yet.")
  # Check if the minimum delay already passed
  time_passed = Time::now - File::ctime(greyfile)
  if time_passed > 60 * $options[:delay]
    verbose("---- yes, whitelisting #{$options[:sender]}")
    `touch #{whitefile}`
    `rm #{greyfile}`
    puts ".X-Greylist: delayed #{time_passed.round} seconds"
  else
    verbose("---- no")
    puts "!Greylisted"
  end
else
  verbose("-- nope, greylisting now")
  `touch #{greyfile}`
  puts "!Greylisted"
end
