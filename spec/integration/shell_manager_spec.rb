require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::ShellManager" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @m = @a.shell_manager
  end

  it "should run shell commands and detect their exit status (sh)" do
    @m.sh("true").should be_true
    @m.sh("false").should be_false
  end

  if INTERPRETER.shell_manager[:unix].available?
    it "should find which program is in the path (which)" do
      @m.which("sh").match(/.\/sh$/).nil?.should be_false
    end

    it "should not find programs that aren't in the path (which)" do
      @m.which("not_a_real_program").should be_nil
    end

    it "should throw exception if command isn't in path (which!)" do
      lambda{ @m.which!("not_a_real_program") }.should raise_error(NotImplementedError, /not_a_real_program/)
    end
  else
    puts "NOTE: Can't use 'which' on this platform in #{__FILE__}"
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

  it "should move files (mv)" do
    @m.mktempdircd do
      file1 = "foo"
      file2 = "bar"
      @m.touch(file1)
      File.exists?(file1).should be_true

      @m.mv(file1, file2).should == file1
      File.exists?(file1).should be_false
      File.exists?(file2).should be_true

      @m.mv(file1, file2).should be_false
    end
  end

  it "should delete files (rm)" do
    @m.mktempdircd do
      file1 = "foo"
      file2 = "bar"
      @m.touch(file1)
      @m.touch(file2)
      File.exists?(file1).should be_true
      File.exists?(file2).should be_true

      @m.rm([file1, file2]) == [file1, file2]
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

      @m.rm_rf(dir) == [dir, file]
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

      @m.rm_rf(dir) == [file, dir]
      File.exists?(file).should be_false
      File.exists?(dir).should be_false
    end
  end

  it "should change the permissions of files (chmod)" do
    @m.mktempdircd do
      target = "foo"
      mode = 0654
      @m.touch(target)
      (File.stat(target).mode ^ (mode | 0100000)).zero?.should be_false

      @m.chmod(mode, target).should == target
      (File.stat(target).mode ^ (mode | 0100000)).zero?.should be_true

      @m.chmod(mode, target).should be_false
    end
  end

  it "should change the permissions of files recursively (chmod_R)" do
    @m.mktempdircd do
      mode = 0754
      dir = "foo/bar"
      file = dir+"/baz"
      @m.mkdir_p(dir)
      @m.touch(file)
      File.exists?(file).should be_true
      File.exists?(dir).should be_true
      (File.stat(file).mode ^ (mode | 0100000)).zero?.should be_false
      (File.stat(dir).mode ^ (mode | 040000)).zero?.should be_false

      @m.chmod_R(mode, dir).should == dir
      (File.stat(file).mode ^ (mode | 0100000)).zero?.should be_true
      (File.stat(dir).mode ^ (mode | 04000)).zero?.should be_false

      @m.chmod_R(mode, dir).should be_false
    end
  end

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
    it "should change the ownership of files (chown)" do
      @m.mktempdircd do
        target = "foo"
        uid = 1
        group = "daemon"
        gid = Etc.getgrnam(group).gid

        @m.touch(target)
        stat = File.stat(target)
        (stat.uid == uid).should be_false
        (stat.gid == gid).should be_false

        @m.chown(uid, group, target).should == target
        stat = File.stat(target)
        (stat.uid == uid).should be_true
        (stat.gid == gid).should be_true

        @m.chown(uid, group, target).should be_false
      end
    end

    it "should change the ownership of files recursively (chown_R)" do
      @m.mktempdircd do
        uid = 1
        group = "daemon"
        gid = Etc.getgrnam(group).gid
        dir = "foo/bar"
        file = dir+"/baz"

        @m.mkdir_p(dir)
        @m.touch(file)
        File.exists?(file).should be_true
        File.exists?(dir).should be_true
        stat = File.stat(file)
        (stat.uid == uid).should be_false
        (stat.gid == gid).should be_false
        stat = File.stat(dir)
        (stat.uid == uid).should be_false
        (stat.gid == gid).should be_false

        @m.chown_R(uid, group, dir).should == dir
        stat = File.stat(file)
        (stat.uid == uid).should be_true
        (stat.gid == gid).should be_true
        stat = File.stat(dir)
        (stat.uid == uid).should be_true
        (stat.gid == gid).should be_true

        @m.chown_R(uid, group, dir).should be_false
      end
    end
  else
    puts "NOTE: Must be root to check 'chown' in #{__FILE__}"
  end
end
