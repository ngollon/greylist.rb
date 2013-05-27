require 'logger'

module Greylist
  module Config
    @values = {      
      :greylisting_delay   => 5,                                 # Minutes until a resent message is accepted
      :graylisting_max_age => 10080,                             # Minutes until a resent message is no longer accepted
      :whitelist_directory => '/var/lib/greylist/whitelist',
      :greylist_directory  => '/var/lib/greylist/greylist',
      :opt_in_directory    => '/var/lib/greylist/opt-in',
      :socketfile          => '/var/run/greylist/greylist.sock',
      :pidfile             => '/var/run/greylist/greylist.pid',
      :logfile             => '/var/log/greylist/greylist.log',
      :loglevel            => Logger::INFO,
    }
    
    def self.method_missing(name)
      return @values[name] if @values.has_key?(name)
      super
    end
  end
end

