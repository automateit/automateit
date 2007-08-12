require 'automateit'

module AutomateIt
  class ShellManager < Plugin::Manager
    alias_methods :sh, :which, :ln, :ln_s, :ln_sF, :rm, :rm_r, :rm_rF, :rmdir, :cp, :cp_R, :mv, :touch, :chmod, :chmod_R, :chown, :chown_R, :own

    def sh(*args) dispatch(*args) end

    def which(command) dispatch(command) end

    class POSIX < Plugin::Driver
      def suitability(method, *args)
        return 3 # TODO how do I know if this has posix?
      end

      def sh(*args)
        log.info("$$$ #{args.join(' ')}")
        return system(*args) if interpreter.writing?
      end

      def which(command)
        data = nil
        rv = Open4.popen4("which", command) do |pid, sin, sout, serr|
          data = sout.read.chomp
        end
        return File.exists?(data.to_s) ? data : nil
      end
    end
  end
end
