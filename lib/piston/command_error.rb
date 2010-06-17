require "piston"

module Piston
  # Raised whenever an argument is not correct during processing.
  class CommandError < ArgumentError; end
end
