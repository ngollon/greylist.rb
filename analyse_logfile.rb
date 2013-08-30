#!/usr/local/bin/ruby

require_relative 'config.rb'

counts = { :white => 0, :grey_delivered => 0, :grey_rejected => 0 }

File.open(Greylist::Config.logfile).each do |line|
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

