# == TemplateManager
#
# TemplateManager renders templates to files.
#
# See the #render method for details.
class AutomateIt::TemplateManager < AutomateIt::Plugin::Manager
  alias_methods :render

  # Render a template.
  #
  # You may specify the +source+ and +target+ as arguments or options. For
  # example, <tt>render(:file => "input", :to => "output")</tt> is the same as
  # <tt>render("input", "output")</tt>.
  #
  # Options:
  # * :file -- Read the template from this file.
  # * :text -- Read the template from this string.
  # * :to -- Render to a file, otherwise returns the rendered string.
  # * :locals -- Hash of variables passed to template as local variables.
  # * :dependencies -- Array of filenames to check timestamps on, only used
  #   when :check is :timestamp.
  # * :backup -- Make a backup? Default is true.
  # * :force -- Render without making a check. Default is false.
  # * :check -- Determines when to render, otherwise uses value of
  #   +default_check+, possible values:
  #   * :compare -- Only render if rendered template is different than the
  #     target's contents or if the target doesn't exist.
  #   * :timestamp -- Only render if the target is older than the template and
  #     dependencies.
  #   * :exists -- Only render if the target doesn't exist.
  #
  # For example, if the file +my_template_file+ contains:
  #
  #   Hello <%=entity%>!
  #
  # You could then execute:
  #
  #   render("my_template_file", "/tmp/out", :check => :compare,
  #          :locals => {:entity => "world"})
  #
  # And this will create a <tt>/tmp/out</tt> file with:
  #
  #   Hello world!
  def render(*options) dispatch(*options) end

  # Get name of default algorithm for performing checks.
  def default_check() dispatch() end

  # Set name of default algorithms to perform checks, e.g., :compare. See the
  # #render :check option for list of check algorithms.
  def default_check=(value) dispatch(value) end
end # class TemplateManager

# Drivers
require 'automateit/template_manager/base.rb'
require 'automateit/template_manager/erb.rb'
