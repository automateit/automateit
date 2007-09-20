AutomateIt_Base = File.dirname(File.expand_path(__FILE__)) unless defined?(AutomateIt_Base)
AutomateIt_Lib = File.join(AutomateIt_Base, "/../lib") unless defined?(AutomateIt_Lib)
AutomateIt_Bin = File.join(AutomateIt_Base, "/../bin") unless defined?(AutomateIt_Bin)

$LOAD_PATH.unshift(AutomateIt_Lib)

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
