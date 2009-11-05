# == ShellManager::BaseLink
#
# An abstract ShellManager driver used by drivers that provide either hard or
# symbolic links.
class AutomateIt::ShellManager::BaseLink < AutomateIt::ShellManager::BaseDriver
  abstract_driver

  # See ShellManager#ln
  def _ln(sources, target, opts={})
    kind = \
      if opts[:symbolic] and opts[:force]
        :ln_sf
      elsif opts[:symbolic]
        :ln_s
      else
        :ln
      end

    missing = []
    sources = [sources].flatten

    if kind == :ln
      raise TypeError.new("source for hard link must be a String") unless sources.size == 1
    end

    for source in sources
      begin
        source_stat = File.stat(source)

        # If linking one node to another, stop if they're the same.
        if sources.size == 1
          if File.symlink?(target)
            link_relative_path = File.readlink(target)
            link_abolute_path = File.expand_path(link_relative_path, File.dirname(target))
            if File.stat(link_abolute_path).ino == source_stat.ino
              next
            end
          end
        end

        # Link source to the target (when a file) or within the target (when a directory).
        peer = peer_for(source, target)
        peer_stat = File.stat(peer)

        if peer_stat.ino == source_stat.ino
          next
        elsif kind == :ln
          missing << source
        elsif Pathname.new(peer).realpath != Pathname.new(source).realpath
          # It's either :ln_s or :ln_sf
          missing << source
        end
      rescue Errno::ENOENT
        # File doesn't exist, so obviously missing
        missing << source
      end
    end
    return false if missing.empty?

    log.debug(PNOTE+"_ln(%s, %s, %s) # => %s" % [kind, sources.inspect, target.inspect, missing.inspect])
    missing = missing.first if missing.size == 1

    displayed = "ln"
    if opts[:symbolic] and opts[:force]
      displayed << " -sf"
    else
      displayed << " -s" if opts[:symbolic]
      displayed << " -f" if opts[:force]
    end

    if kind == :ln
      log.info(PEXEC+"#{displayed} #{missing} #{target}")
      FileUtils.ln(missing, target, _fileutils_opts) && missing
    else
      log.info(PEXEC+"#{displayed} #{String === missing ? missing : missing.join(' ')} #{target}")
      FileUtils.send(kind, missing, target, _fileutils_opts) && missing
    end
    return missing
  end
end
