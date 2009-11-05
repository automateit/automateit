require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

PACKAGE_FOUND_ERROR = %q{ERROR: Found the '%s' package installed for %s. You're probably not using this obscure package and should remove it so that this test can run. In the unlikely event that you actually rely on this package, change the spec to test with another unused package.}
PACKAGE_DRIVER_MISSING_ERROR = "NOTE: Can't check %s on this platform, #{__FILE__}"

if not INTERPRETER.euid?
  puts "NOTE: Can't check 'euid' on this platform, #{__FILE__}"
elsif not INTERPRETER.superuser?
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

    # Uninstall the +packages+ using the given +opts+.
    def uninstall_package(packages, opts={})
      opts[:quiet] = true
      return @d.uninstall(packages, opts)
    end

    # Install the +packages+ using the given +opts+.
    def install_package(packages, opts={})
      opts[:quiet] = true #IK# Comment this out to see what each package manager is doing
      opts[:force] = [:pecl, :pear].include?(@d.token)
      return @d.install(packages, opts)
    end

    # Return array of arguments to use with #install_package and #uninstall_package for +package+ and optional +version+.
    def arguments(package, version=nil)
      response = [package]
      response << {:version => version} if version
      return response
    end

    # Some specs below leave side-effects which others depend on, although
    # these are clearly documented within the specs. This is necessary
    # because doing proper setup/teardown for each test would make it run 5x
    # slower and take over a minute. Although this approach is problematic,
    # the performance boost is worth it.

    it "should not install an invalid package" do
      @d.log.silence(Logger::FATAL) do
        lambda{ install_package(@fake_package) }.should raise_error(ArgumentError)
      end
    end

    it "should install a package" do
      install_package(*arguments(@package, @version)).should be_true
      # Leaves behind an installed package
    end

    it "should not re-install an installed package" do
      # Expects package to be installed
      install_package(*arguments(@package, @version)).should be_false
    end

    it "should find an installed package" do
      # Expects package to be installed
      @d.installed?(*arguments(@package, @version)).should be_true
      @d.not_installed?(*arguments(@package, @version)).should be_false
    end

    it "should not find a package that's not installed" do
      @d.installed?(@fake_package).should be_false
      @d.not_installed?(@fake_package).should be_true
    end

    it "should find group of packages" do
      @d.installed?(@package, @fake_package, :details => true).should == [false, [@package]]
      @d.not_installed?(@package, @fake_package, :details => true).should == [false, [@fake_package]]
      # Leaves behind an installed package
    end

    it "should uninstall a package" do
      # Expects package to be installed
      uninstall_package(*arguments(@package, @version)).should be_true
    end

    it "should not uninstall a package that's not installed" do
      uninstall_package(*arguments(@package, @version)).should be_false
    end
  end

  #-----------------------------------------------------------------------

  targets = {
    :apt => "nomarch", # Obscure package for extracting ARC files from the 80's
    :yum => "nomarch", # Obscure package for extracting ARC files from the 80's
    :portage => "arc", # Obscure package for extracting ARC files from the 80's
    :gem => "s33r", # Alpha-grade package its author deprecated in favor of another
    :gem => ["s33r", "0.5.4"], # Specific, old version of s33r.
    :egg => "_sre.py", # Slower reimplementation of ancient Python Regexps
    :pear => "File_DICOM", # Obscure package for DICOM X-rays, abandoned in 2003
    :pecl => "ecasound", # Obscure package for Ecasound libs, abandoned in 2003
    :cpan => "Acme::please", # Insane gimmick port of intercal's please statements
  }

  if INTERPRETER.tagged?(:centos)
    # CentOS lacks "nomarch", so use a less obscure archiver from the early 90's.
    targets[:yum] = "arj"
  end

  targets.each_pair do |driver_token, package|
    # Run the following from the shell to skip package tests:
    #   export AUTOMATEIT_SPEC_SKIP_PACKAGES=1
    # Or clear it out:
    #   unset AUTOMATEIT_SPEC_SKIP_PACKAGES
    next unless ENV["AUTOMATEIT_SPEC_SKIP_PACKAGES"].nil?

    driver = INTERPRETER.package_manager[driver_token]
    if driver.available?
      describe driver.class.to_s do
        it_should_behave_like "AutomateIt::PackageManager"

        before(:all) do
          @d = @m[driver_token]
          if package.kind_of?(Array)
            @package, @version = package
          else
            @package = package
            @version = nil
          end
          raise PACKAGE_FOUND_ERROR % [@package, @d.class] if @d.installed?(@package)
        end
      end
    else
      puts PACKAGE_DRIVER_MISSING_ERROR % driver.class
    end
  end
end
