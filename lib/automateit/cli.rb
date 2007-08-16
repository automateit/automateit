require "rubygems"
require "active_support"
require "automateit"

module AutomateIt
  class CLI
    def initialize(opts={})
      interpreter = AutomateIt.new(opts)
      if recipe = opts.delete(:recipe)
        interpreter.invoke(recipe)
      elsif code = opts.delete(:eval)
        interpreter.instance_eval(code)
      else
        require "irb"
        unless opts[:quiet]
          puts "### AutomateIt Shell v#{AutomateIt::VERSION}"
          puts "### <CTRL-D> to quit, <Tab> to auto-complete"
        end
        IRB.setup(__FILE__)
        irb = IRB::Irb.new
        IRB.instance_variable_get(:@CONF)[:MAIN_CONTEXT] = irb.context
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))
        irb.eval_input
      end
    end
  end
end
