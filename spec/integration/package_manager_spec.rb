require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

PACKAGE_FOUND_ERROR = %q{ERROR: Found the '%s' package installed for %s. You're probably not using this obscure package and should remove it so that this test can run. In the unlikely event that you actually rely on this package, change the spec to test with another unused package.}
PACKAGE_DRIVER_MISSING_ERROR = %{\nNOTE: %s is not available for testing on this platform: #{__FILE__}}

if not INTERPRETER.superuser?
  puts "NOTE: Must be root to check #{__FILE__}"
else
  describe "AutomateIt::PackageManager", :shared => true do
    before(:all) do
      @level = Logger::WARN
      @a = AutomateIt.new(:verbosity => @level)
      @m = @a.package_manager
      @fake_package = "not_a_real_package"
    end

    after(:all) do
      @d.uninstall(@package, :quiet => true)
    end

    # Some specs below leave side-effects which others depend on, although
    # these are clearly documented within the specs. This is necessary
    # because doing proper setup/teardown for each test would make it run 5x
    # slower and take over a minute. Although this approach is problematic,
    # the performance boost is worth it.

    it "should not install an invalid package" do
      # Temporarily quiet down logging so we don't get warnings during the test
      @d.log.level = Logger::FATAL
      lambda{ @d.install(@fake_package, :quiet => true) }.should raise_error(ArgumentError)
      @d.log.level = @level
    end

    it "should install a package" do
      @d.install(@package, :quiet => true).should be_true
      # Leaves behind an installed package
    end

    it "should not re-install an installed package" do
      # Expects package to be installed
      @d.install(@package, :quiet => true).should be_false
    end

    it "should find an installed package" do
      # Expects package to be installed
      @d.installed?(@package).should be_true
      @d.not_installed?(@package).should be_false
    end

    it "should not find a package that's not installed" do
      @d.installed?(@fake_package).should be_false
      @d.not_installed?(@fake_package).should be_true
    end

    it "should find group of packages" do
      @d.installed?(@package, @fake_package, :list => true).should == [@package]
      @d.not_installed?(@package, @fake_package, :list => true).should == [@fake_package]
      # Leaves behind an installed package
    end

    it "should uninstall a package" do
      # Expects package to be installed
      @d.uninstall(@package, :quiet => true).should be_true
    end

    it "should not uninstall a package that's not installed" do
      @d.uninstall(@package, :quiet => true).should be_false
    end
  end

  #-----------------------------------------------------------------------

  {
    :apt => "nomarch", # Obscure package for extracting ARC files from the early 80's
    :yum => "nomarch", # Obscure package for extracting ARC files from the early 80's
    :gem => "s33r", # Alpha-grade package its author deprecated in favor of another
    ### :easy_install => "_sre.py", # Slower reimplementation of ancient Python Regexps
    ### :cpan => "Acme::please", # Insane gimmick port of intercal's please statements
  }.each_pair do |driver_token, package|
    driver = INTERPRETER.package_manager[driver_token]
    if driver.available?
      describe driver.class.to_s do
        it_should_behave_like "AutomateIt::PackageManager"

        before(:all) do
          @d = @m[driver_token]
          @package = package
          raise PACKAGE_FOUND_ERROR % [@package, @d.class] if @d.installed?(@package)
        end

        if :gem == driver_token
          it "should fail reasonably when dealing with broken Gems" do
            raise "Found Gem 'sys-cpu' installed, you must remove it to test how broken packages are handled" if @d.installed?("sys-cpu")
            # Temporarily quiet down logging so we don't get warnings during the test
            old_level = @d.log.level
            @d.log.level = Logger::FATAL
            lambda{ @d.install("sys-cpu", :quiet => true) }.should raise_error(ArgumentError, /invalid/)
            @d.log.level = old_level
            # Cleanup, just in case
            @d.uninstall("sys-cpu").should be_false
          end
        end
      end
    else
      puts PACKAGE_DRIVER_MISSING_ERROR % driver.class
    end
  end
end
