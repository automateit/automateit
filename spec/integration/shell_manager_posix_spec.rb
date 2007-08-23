require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

if not INTERPRETER.address_manager[:linux].available?
  puts "NOTE: This platform can't check #{__FILE__}"
else
  describe "AutomateIt::ShellManager::POSIX" do
    before(:all) do
      @a = AutomateIt.new(:verbosity => Logger::WARN)
      @m = @a.shell_manager
    end

    it "should run shell commands and detect their exit status (sh)" do
      @m.sh("true").should be_true
      @m.sh("false").should be_false
    end

    it "should find which program is in the path (which)" do
      @m.which("sh").match(/.\/sh$/).nil?.should be_false
    end

    it "should not find programs that aren't in the path (which)" do
      @m.which("not_a_real_program").should be_nil
    end

    it "should throw exception if command isn't in path (which!)" do
      lambda{ @m.which!("not_a_real_program") }.should raise_error(NotImplementedError, /not_a_real_program/)
    end

    it "should change directories (cd)" do
      before = Dir.pwd
      @m.cd("/")
      Dir.pwd.should == "/"
      @m.cd(before)
      Dir.pwd.should == before
    end

    it "should change directories using a block (cd)" do
      before = Dir.pwd
      @m.cd("/") do
        Dir.pwd.should == "/"
      end
      Dir.pwd.should == before
    end

    it "should locate the current directory (pwd)" do
      @m.pwd.should == Dir.pwd
    end

    it "should create a directory when needed (mkdir)" do
      @m.mktempdircd do
        target = "foo"
        File.directory?(target).should be_false

        @m.mkdir(target).should == [target]
        File.directory?(target).should be_true

        @m.mkdir(target).should be_false
      end
    end

    it "should create nested directories when needed (mkdir_p)" do
      @m.mktempdircd do
        target = "foo/bar/baz"
        File.directory?(target).should be_false

        @m.mkdir_p(target).should == [target]
        File.directory?(target).should be_true

        @m.mkdir_p(target).should be_false
      end
    end

    it "should remove directory when needed (rmdir)" do
      @m.mktempdircd do
        target = "foo"
        @m.mkdir(target).should == [target]

        @m.rmdir(target).should == [target]
        File.directory?(target).should be_false
      end
    end

    it "should create hard links when needed (ln)" do
      @m.mktempdircd do
        source = "foo"
        target = "bar"
        @m.touch(source).should == [source]
        File.exists?(source).should be_true
        File.exists?(target).should be_false

        @m.ln(source, target).should == source
        File.stat(target).nlink.should > 1

        @m.ln(source, target).should be_false
      end
    end

    it "should create symlinks when needed (ln_s)" do
      @m.mktempdircd do
        source = "foo"
        target = "bar"
        @m.touch(source).should == [source]
        File.exists?(source).should be_true
        File.exists?(target).should be_false

        @m.ln_s(source, target).should == source
        File.lstat(target).symlink?.should be_true

        @m.ln(source, target).should be_false
      end
    end

    it "should create symlinks that replace existing entry (ln_sf)" do
      @m.mktempdircd do
        source = "foo"
        intermediate = "baz"
        target = "bar"
        @m.touch(source).should == [source]
        File.exists?(source).should be_true
        File.exists?(target).should be_false

        @m.ln_s(intermediate, target).should == intermediate
        File.lstat(target).symlink?.should be_true

        @m.ln_sf(source, target).should == source
        File.lstat(target).symlink?.should be_true
        File.readlink(target).should == source
      end
    end

    # TODO implement gap

    it "should delete files (rm)" do
      @m.mktempdircd do
        file1 = "foo"
        file2 = "bar"
        @m.touch(file1)
        @m.touch(file2)
        File.exists?(file1).should be_true
        File.exists?(file2).should be_true

        @m.rm([file1, file2])
        File.exists?(file1).should be_false
        File.exists?(file2).should be_false
      end
    end

    it "should delete recursively (rm_r)" do
      @m.mktempdircd do
        dir = "foo/bar"
        file = dir+"/baz"
        @m.mkdir_p(dir)
        @m.touch(file)
        File.exists?(file).should be_true
        File.exists?(dir).should be_true

        @m.rm_rf(dir)
        File.exists?(file).should be_false
        File.exists?(dir).should be_false
      end
    end

    it "should delete recursively and forcefully (rm_rf)" do
      @m.mktempdircd do
        dir = "foo/bar"
        file = dir+"/baz"
        @m.mkdir_p(dir)
        @m.touch(file)
        File.exists?(file).should be_true
        File.exists?(dir).should be_true
        # FIXME chmod a file so that rm_r will fail

        @m.rm_rf(dir)
        File.exists?(file).should be_false
        File.exists?(dir).should be_false
      end
    end

    # TODO implement gap

    it "should create files and change their timestamps (touch)" do
      @m.mktempdircd do
        target = "foo"
        File.exists?(target).should be_false

        @m.touch(target)
        File.exists?(target).should be_true
        before = File.mtime(target)

        @m.touch(target)
        after = File.mtime(target)
        before.should <= after
      end
    end

    if INTERPRETER.superuser?
      # TODO implement chown spec
    else
      puts "\nNOTE: Must be root to check 'chown' in #{__FILE__}"
    end
  end
end
