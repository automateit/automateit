module Nitpick
  module ClassMethods
    # Use to manage nitpick message for debugging AutomateIt internals.
    #
    # Arguments:
    # * nil -- Returns boolean of whether nitpick messages will be displayed.
    # * Boolean -- Sets nitpick state.
    # * String or Symbol -- Displays nitpick message if state is on.
    #
    # Example:
    #   nitpick true
    #   nitpick "I'm nitpicking"
    def nitpick(value=nil)
      case value
      when NilClass: @nitpick
      when TrueClass, FalseClass: @nitpick = value
      when String, Symbol: puts "%% #{value}" if @nitpick
      else raise TypeError.new("Unknown nitpick type: #{value.class}")
      end
    end
  end

	def self.included(receiver)
		receiver.extend(ClassMethods)
	end

  include ClassMethods
  extend ClassMethods
end
