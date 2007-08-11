$LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), "/../lib")

ENV.delete("AUTOMATEIT_PROJECT")

require 'automateit'
