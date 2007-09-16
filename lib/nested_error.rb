# == NestedError
#
# An exception class that records the cause of another error. Useful when you
# need to raise a general kind of error, yet still be able to determine the
# underlying cause.
#
# Example:
#
#   class MyGeneralError < NestedError; end
#
#   begin
#     begin
#       # Cause a specific error
#       1/0 # Divide by zero error
#     rescue Exception => e
#       # Wrap the specific error in a general, nested error
#       raise MyGeneralError("Something bad happened!", e)
#     end
#   rescue MyGeneralError => e
#     # Intercept the nested error and inspect the cause
#     puts e.message # => "Something bad happened!"
#     puts e.cause.message # => "divided by 0"
#   end
class NestedError < StandardError
  attr_accessor :cause

  # Create a NestedObject with a +message+ String and a +cause+ Exception.
  def initialize(message, cause)
    self.cause = cause
    super(message)
  end
end

