module DEVS
  class NoSuchChildError < StandardError; end
  class BadSynchronisationError < StandardError; end
  class NoSuchPortError < Exception; end
  class InvalidPortTypeError < StandardError; end
  class InvalidPortHostError < StandardError; end
  class MessageAlreadySentError < StandardError; end
  class FeedbackLoopError < StandardError; end
  class UnobservablePortError < StandardError; end
end
