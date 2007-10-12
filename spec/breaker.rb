require File.join(File.dirname(File.expand_path(__FILE__)), "/spec_helper.rb")

describe "Breaker" do
  it "should breakpoint within the RSpec environment" do
    require "breakpoint"
    breakpoint
  end
end
