module AutomateIt
  # == AutomateIt::Error
  #
  # Wraps errors while preserving their cause. Used by the Interpreter to
  # display user-friendly error messages.
  #
  # See NestedError for class API.
  class Error < ::NestedError
  end
end
