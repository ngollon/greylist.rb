#!/usr/bin/ruby

require_relative '/etc/greylist.rb/config.rb'

counts = { :white => 0, :grey_delivered => 0, :grey_rejected => 0 }

if ARGV.count > 0
  desired_user = ARGV[0]
  puts "Stats for user #{desired_user}"
end

user = ""

File.open(Greylist::Config.logfile).each do |line|
  if line =~ /Incomming.* (\w+)$/ 
    user = $1        
  end

  next if not desired_user.nil? and user != desired_user 

  if line =~ /ERROR/
    puts line
  end

  if line =~ /whitelisted/ 
    counts[:white] += 1
  end

  if line =~ /Greylisted/
    counts[:grey_rejected] += 1
  end

  if line =~ /successful/
    counts[:grey_rejected] -= 1
    counts[:grey_delivered] += 1
  end
end

puts "Whitelisted messages:   #{counts[:white]}"
puts "Greylisted but retried: #{counts[:grey_delivered]}"
puts "Greylisted, no retry:   #{counts[:grey_rejected]}"

