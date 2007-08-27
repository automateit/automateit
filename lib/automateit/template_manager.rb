module AutomateIt
  # == TemplateManager
  #
  # TemplateManager renders templates to files. See TemplateManager::ERB for
  # complete documentation.
  class TemplateManager < Plugin::Manager
    require 'automateit/template_manager/erb.rb'

    alias_methods :render

    # See documentation for TemplateManager::ERB#render
    def render(*options) dispatch(*options) end

    # See documentation for TemplateManager::ERB#default_check
    def default_check() dispatch() end

    # See documentation for TemplateManager::ERB#default_check=
    def default_check=(value) dispatch(value) end
  end # class TemplateManager
end # module AutomateIt
