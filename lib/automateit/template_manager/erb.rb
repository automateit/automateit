# == TemplateManager::ERB
#
# Renders ERB templates for TemplateManager.
class AutomateIt::TemplateManager::ERB < AutomateIt::TemplateManager::BaseDriver
  depends_on :nothing

  def suitability(method, *args) # :nodoc:
    return 1
  end

  # See documentation for TemplateManager#render
  def render(*options)
    return _render_helper(*options) do |o|
      HelpfulERB.new(o[:text], o[:filename]).result(o[:binder])
    end
  end
end
