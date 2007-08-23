require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::EditManager for strings" do
  before(:all) do
    @a = AutomateIt.new(:verbosity => Logger::WARN)
  end

  before(:each) do
    @input = "This\nis\n\a\nstring."
  end

  it "should pass contents" do
    @a.edit(:string => @input) do
      contents.should == "This\nis\n\a\nstring."
    end
  end

  it "should pass params" do
    @a.edit(:string => @input, :params => {:hello => "world"}) do
      params[:hello].should == "world"
    end
  end

  it "should find contained lines" do
    @a.edit(:string => @input) do
      contains?(/This/).should == true
    end
  end

  it "should prepend lines to the top" do
    output = @a.edit(:string => @input) do
      prepend "PREPEND"
      prepend "PREPEND" # Duplicate line will be ignored.
    end
    output.should =~ /\APREPEND\nThis/s
  end

  it "should prepend lines to the top unless they match an expression" do
    output = @a.edit(:string => @input) do
      prepend "PREPEND", :unless => /PR.+ND/
      prepend "PRETENDER", :unless => /PR.+ND/ # Regexp matches.
    end
    output.should =~ /\APREPEND\nThis/s
  end

  it "should append lines to the bottom" do
    output = @a.edit(:string => @input) do
      append "APPEND"
      append "APPEND" # Duplicate line will be ignored.
    end
    output.should =~ /string\.\nAPPEND\Z/s
  end

  it "should append lines to the bottom unless they match an expression" do
    output = @a.edit(:string => @input) do
      append "APPEND", :unless => /^APP/
      append "APPENDIX", :unless => /^APP/ # Regexp matches.
    end
    output.should =~ /^string\.\nAPPEND\Z/s
  end

  it "should delete lines" do
    output = @a.edit(:string => @input) do
      delete "This"
    end
    # output.should !~ /This/ # XXX !~ is broken in rspec?
    (output !~ /This/).should == true
  end

  it "should comment lines" do
    output = @a.edit(:string => @input) do
      comment_style "<", ">"
      comment "This"
    end
    output.should =~ /^<This>$/s
  end

  it "should uncomment lines" do
    output = @a.edit(:string => @input) do
      comment_style "T", "s"
      uncomment "hi"
    end
    output.should =~ /^hi\nis\n/s
  end

  it "should replace strings" do
    output = @a.edit(:string => @input) do
      replace "This", "That"
    end
    output.should =~ /^That\nis\n/s
  end

  it "should manipulate contents" do
    output = @a.edit(:string => @input) do
      manipulate do |buffer|
        buffer.gsub(/i/, "@")
      end
    end
    output.should =~ /^Th@s\n@s\n/
  end

  it "should tell if content is different after an edit" do
    @a.edit(:string => @input) do
      different?.should == false
      append "changing"
      different?.should == true
    end
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
    result = @a.edit(:file => @filename) do
      append "APPEND"
    end
    result.should be_true
  end

  it "should not rewrite an unchanged file" do
    File.should_receive(:read).with(@filename).and_return(@input)
    result = @a.edit(:file => @filename) do
      # Do nothing
    end
    result.should be_false
  end
end
