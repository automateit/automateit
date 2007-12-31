require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::PackageManager::DPKG do
  before :all do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @m = @a.package_manager
    @d = @m.drivers[:dpkg]
  end

  it "should handle hash arguments" do
    # Given
    @d.should_receive(:_raise_unless_available).any_number_of_times.and_return(true)
    @d.should_receive(:installed?).and_return(false, ["foonix"])
    @a.should_receive(:sh).and_return do |cmd|
      if cmd =~ /dpkg.*install.*\bfoonix-1.2.3.deb\b/
        true
      else
        raise "Unknown cmd: #{cmd}"
      end
    end

    @d.install({:foonix => "foonix-1.2.3.deb"}, :with => :dpkg)
  end
end
