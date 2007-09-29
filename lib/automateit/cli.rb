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
    # Examples:
    #   AutomateIt::CLI.run("myrecipe.rb")
    #   AutomateIt::CLI.run(:recipe => "myrecipe.rb")
    #   AutomateIt::CLI.run(:eval => "42")
    #
    # Options:
    # * :tags -- Array of tags to add for this run.
    # * :project -- Project directory to load.
    # * :recipe -- Recipe file to execute.
    # * :eval -- Evaluate this string.
    # * :quiet -- Don't print shell header.
    def self.run(*a)
      args, opts = args_and_opts(*a)
      recipe = args.first || opts[:recipe]
      if recipe and not opts[:project]
        opts[:project] = File.join(File.dirname(recipe), "..")
        opts[:guessed_project] = true
      end

      opts[:verbosity] ||= Logger::INFO

      if opts[:create]
        Project::create(opts)
      elsif code = opts.delete(:eval)
        interpreter = AutomateIt.new(opts)
        interpreter.instance_eval(code)
      elsif recipe
        AutomateIt.invoke(recipe, opts)
      else
        # Welcome messages
        display = lambda{|msg| puts msg if opts[:verbosity] <= Logger::INFO}
        display.call PNOTE+"AutomateIt Shell v#{AutomateIt::VERSION} #{$0}"

        # Create and connect instances
        require "irb"
        IRB.setup(__FILE__)
        # XXX irb: warn: can't alias context from irb_context.
        irb = IRB::Irb.new
        opts[:irb] = irb
        IRB.conf[:MAIN_CONTEXT] = irb.context
        interpreter = AutomateIt.new(opts)
        irb.context.workspace.instance_variable_set(:@binding, interpreter.send(:binding))

        # Tab completion
        message = "<CTRL-D> to quit"
        begin
          require 'irb/completion'
          irb.context.auto_indent_mode = true
          irb.context.load_modules << 'irb/completion' unless irb.context.load_modules.include?('irb/completion')
          irb.context.instance_eval{ @use_readline = true }
          message << ", <Tab> to auto-complete"
        rescue LoadError
          # Ignore
        end
        display.call PNOTE+message

        # Set prompt
        unless opts[:custom_prompt] == false
          irb.context.prompt_i = "ai> "
          irb.context.prompt_s = "ai%l "
          irb.context.prompt_c = "ai* "
          begin
            irb.context.prompt_n = "ai%i " 
          rescue NoMethodError
            # Not available on Ruby 1.8.2 bundled with Mac OS X 10.4 Tiger
          end
        end

        # Run loop to read user input
        irb.eval_input
      end
    end
  end
end
