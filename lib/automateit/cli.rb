module AutomateIt
  # == CLI
  #
  # The CLI class provides AutomateIt's command-line interface. It's
  # responsible for invoking recipes from the command line, starting the
  # interactive shell and creating projects. It's run from
  # <tt>bin/automate</tt>.
  class CLI
    # Create a new CLI interpreter. If no :recipe or :eval option is provided,
    # it starts an interactive IRB session for the Interpreter.
    #
    # Options:
    # * :project -- Project directory to load.
    # * :recipe -- Recipe file to execute.
    # * :eval -- Evaluate this string.
    # * :quiet -- Don't print shell header.
    def initialize(opts={})
      opts[:project] ||= opts[:recipe] ? File.join(File.dirname(opts[:recipe]), "..") : "."
      if opts[:create]
        Project::create(opts)
      elsif opts[:recipe]
        AutomateIt.invoke(opts[:recipe], opts)
      elsif code = opts.delete(:eval)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval(code)
      else
        require "irb"
        unless opts[:quiet]
          puts PNOTE+"AutomateIt Shell v#{AutomateIt::VERSION}"
          puts PNOTE+"<CTRL-D> to quit, <Tab> to auto-complete"
        end
        IRB.setup(__FILE__)
        irb = IRB::Irb.new
        opts[:irb] = irb
        IRB.conf[:MAIN_CONTEXT] = irb.context
        interpreter = AutomateIt.new(opts)
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))
        unless opts[:custom_prompt] == false
          irb.context.prompt_i = "ai> "
          irb.context.prompt_s = "ai%l "
          irb.context.prompt_c = "ai* "
          irb.context.prompt_n = "ai%i "
        end
        irb.eval_input
      end
    end
  end
end
