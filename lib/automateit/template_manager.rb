# == TemplateManager
#
# TemplateManager renders templates to files. See TemplateManager::ERB for
# complete documentation.
class AutomateIt::TemplateManager < AutomateIt::Plugin::Manager
  alias_methods :render

  # See documentation for TemplateManager::ERB#render
  def render(*options) dispatch(*options) end

  # See documentation for TemplateManager::ERB#default_check
  def default_check() dispatch() end

  # See documentation for TemplateManager::ERB#default_check=
  def default_check=(value) dispatch(value) end
end # class TemplateManager

# == TemplateManager::BaseDriver
#
# Base class for all TemplateManager drivers.
class AutomateIt::TemplateManager::BaseDriver < AutomateIt::Plugin::Driver
end

# Drivers
require 'automateit/template_manager/erb.rb'
