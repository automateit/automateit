# == TagManager::YAML
#
# A TagManager driver that reads tags from a YAML file.
class AutomateIt::TagManager::YAML < AutomateIt::TagManager::Struct
  depends_on :nothing

  def suitability(method, *args) # :nodoc:
    return 5
  end

  # Options:
  # * :file -- File to read tags from. The file is preprocessed with ERB and
  #   must produce YAML content.
  def setup(opts={})
    if filename = opts.delete(:file)
      contents = _read(filename)
      output = HelpfulERB.new(contents, filename).result

      text = AutomateIt::TagManager::TagParser.normalize(output)
      opts[:struct] = ::YAML::load(text)
    end
    super(opts)
  end

  def _read(filename)
    return File.read(filename)
  end
  private :_read
end
