module AutomateIt
  # == CLI
  #
  # The CLI class provides AutomateIt's command-line interface. It's
  # responsible for invoking recipes from the command line, starting the
  # interactive shell and creating projects. It's run from
  # <tt>bin/automate</tt>.
  class CLI < Common
    # Create a new CLI interpreter. If no :recipe or :eval option is provided,
    # it starts an interactive IRB session for the Interpreter.
    #
    # Options:
    # * :project -- Project directory to load.
    # * :recipe -- Recipe file to execute.
    # * :eval -- Evaluate this string.
    # * :quiet -- Don't print shell header.
    def self.run(opts={})
      opts[:project] ||= opts[:recipe] ? File.join(File.dirname(opts[:recipe]), "..") : "."
      if opts[:create]
        Project::create(opts)
      elsif code = opts.delete(:eval)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval(code)
      elsif opts[:recipe]
        AutomateIt.invoke(opts[:recipe], opts)
      else
        require "irb"

        # Welcome messages
        unless opts[:quiet]
          puts PNOTE+"AutomateIt Shell v#{AutomateIt::VERSION}"
          puts PNOTE+"<CTRL-D> to quit, <Tab> to auto-complete"
        end

        # Create and connect instances
        IRB.setup(__FILE__)
        irb = IRB::Irb.new
        opts[:irb] = irb
        IRB.conf[:MAIN_CONTEXT] = irb.context
        interpreter = AutomateIt.new(opts)
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))

        # Tab completion
        require 'irb/completion'
        irb.context.auto_indent_mode = true
        unless irb.context.load_modules.include?('irb/completion')
          irb.context.load_modules << 'irb/completion'
        end
        irb.context.instance_eval do
          # Bug in IRB::Context prints useless message if you use the method
          ### irb.context.use_readline = true
          @use_readline = true
        end

        # Set prompt
        unless opts[:custom_prompt] == false
          irb.context.prompt_i = "ai> "
          irb.context.prompt_s = "ai%l "
          irb.context.prompt_c = "ai* "
          irb.context.prompt_n = "ai%i "
        end

        # Run loop to read user input
        irb.eval_input
      end
    end
  end
end
