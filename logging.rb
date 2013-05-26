module Greylisting
  module Logging
    def logger
      Logging.logger
    end

    def configure(out, loglevel)
      @out = out
      @level = loglevel
    end

    def self.logger
      @logger ||= Logger.new(@out || STDOUT)
      @logger.level = @level
      @logger
    end
    
    module_function :configure
  end
end
