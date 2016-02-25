module DEVS
  class NullLogger
    def debug(s); end
    def info(s); end
    def warn(s); end
    def error(s); end
    def fatal(s); end
  end

  class << self
    attr_accessor :logger
  end
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::INFO

  module Logging
    # Send a debug message
    #
    # @param string [String] the string to log
    def debug(string)
      DEVS.logger.debug(string)
    end

    # Send a info message
    #
    # @param string [String] the string to log
    def info(string)
      DEVS.logger.info(string)
    end

    # Send a warning message
    #
    # @param string [String] the string to log
    def warn(string)
      DEVS.logger.warn(string)
    end

    # Send an error message
    #
    # @param string [String] the string to log
    def error(string)
      DEVS.logger.error(string)
    end

    module_function :debug, :info, :warn, :error
  end
end
