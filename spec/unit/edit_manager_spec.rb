require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::EditManager for strings" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
  end

  before(:each) do
    @input = "This\nis\n\a\nstring."
  end

  it "should pass contents" do
    @a.edit(:text => @input) do
      contents.should == "This\nis\n\a\nstring."
    end
  end

  it "should pass params" do
    @a.edit(:text => @input, :params => {:hello => "world"}) do
      params[:hello].should == "world"
    end
  end

  it "should find if buffer contains lines by regexp" do
    @a.edit(:text => @input) do
      contains?(/This/).should == true
    end
  end

  it "should find if buffer contains lines by string" do
    @a.edit(:text => @input) do
      contains?("This").should == true
    end
  end

  it "should prepend lines to the top" do
    output = @a.edit(:text => @input) do
      prepend "PREPEND"
      prepend "PREPEND" # Duplicate line will be ignored.
    end
    output.should =~ /\APREPEND\nThis/s
  end

  it "should prepend lines to the top unless they match an expression" do
    output = @a.edit(:text => @input) do
      prepend "PREPEND", :unless => /PR.+ND/
      prepend "PRETENDER", :unless => /PR.+ND/ # Regexp matches.
    end
    output.should =~ /\APREPEND\nThis/s
  end

  it "should append lines to the bottom" do
    output = @a.edit(:text => @input) do
      append "APPEND"
      append "APPEND" # Duplicate line will be ignored.
    end
    output.should =~ /string\.\nAPPEND\Z/s
  end

  it "should append lines to the bottom unless they match an expression" do
    output = @a.edit(:text => @input) do
      append "APPEND", :unless => /^APP/
      append "APPENDIX", :unless => /^APP/ # Regexp matches.
    end
    output.should =~ /^string\.\nAPPEND\Z/s
  end

  it "should delete lines" do
    output = @a.edit(:text => @input) do
      delete "This"
    end
    output.should_not =~ /This/
  end

  it "should comment lines" do
    output = @a.edit(:text => @input) do
      comment_style "<", ">"
      comment "This"
    end
    output.should =~ /^<This>$/s
  end

  it "should uncomment lines" do
    output = @a.edit(:text => @input) do
      comment_style "T", "s"
      uncomment "hi"
    end
    output.should =~ /^hi\nis\n/s
  end

  it "should replace strings" do
    output = @a.edit(:text => @input) do
      replace "This", "That"
    end
    output.should =~ /^That\nis\n/s
  end

  it "should manipulate contents" do
    output = @a.edit(:text => @input) do
      manipulate do |buffer|
        buffer.gsub(/i/, "@")
      end
    end
    output.should =~ /^Th@s\n@s\n/
  end

  it "should tell if content is different after an edit" do
    @a.edit(:text => @input) do
      different?.should == false
      append "changing"
      different?.should == true
    end
  end

  it "should provide session with access to interpreter" do
    @a.lookup["foo"] = "bar"
    output = @a.edit(:text => @input) do
      manipulate do |b|
        lookup "foo"
      end
    end
    output.should == "bar"
  end

  it "should raise exceptions for invalid methods" do
    lambda {
      @a.edit(:text => @input) do
        qwoiuerjzxiuo
      end
    }.should raise_error(NameError, /qwoiuerjzxiuo/)
  end
end

describe "AutomateIt::EditManager for files" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @filename = "input"
  end

  before(:each) do
    @input = "This\nis\n\a\nstring."
  end

  it "should edit a file" do
    File.should_receive(:read).with(@filename).and_return(@input)
    File.should_receive(:open).with(@filename, "w+").and_return(true)
    result = @a.edit(:file => @filename, :backup => false) do
      append "APPEND"
    end
    result.should be_true
  end

  it "should not rewrite an unchanged file" do
    File.should_receive(:read).with(@filename).and_return(@input)
    result = @a.edit(:file => @filename, :backup => false) do
      # Do nothing
    end
    result.should be_false
  end

  it "should default to editing a file" do
    File.should_receive(:read).with(@filename).and_return(@input)
    result = @a.edit(@filename, :backup => false) do
      # Do nothing
    end
    result.should be_false
  end

  it "should fail to editing non-existent file" do
    lambda {
      @a.edit(@filename) do
        # Do nothing
      end
    }.should raise_error(Errno::ENOENT)
  end
end

describe "AutomateIt::EditManager for files in preview mode" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
    @a.preview = true
    @filename = "input"
  end

  it "should not fail to editing a non-existent file" do
    @a.edit(@filename) do
      # Do nothing
    end
  end

  it "should not fail when reading a non-existent file" do
    result = @a.edit(@filename, :backup => false) do
      # Do nothing
    end
    result.should be_false
  end

  it "should not write changes" do
    File.should_receive(:exists?).any_number_of_times.with(@filename).and_return(true)
    File.should_receive(:read).with(@filename).and_return(@input)
    @a.shell_manager.should_receive(:cp).and_return(true)
    result = @a.edit(:file => @filename, :backup => false) do
      append "APPEND"
    end
    result.should be_true
  end
end
