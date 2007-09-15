$LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), "/../lib")

# Remove environmental variables that will contaminate tests
ENV.delete("AUTOMATEIT_PROJECT")

require 'automateit'

# Create a global instance, using WARN verbosity so that
# INTERPRETER.mktempdircd calls don't generate output.
unless defined?(INTERPRETER)
  INTERPRETER = AutomateIt.new(:verbosity => Logger::WARN) 
end

# Inject matchers into interpreter, e.g., 'should be_true'
INTERPRETER.class.send(:include, Spec::Matchers)
