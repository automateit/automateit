require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::FieldManager", :shared => true do
  before(:all) do
    @a = AutomateIt.new
    @a.tags << "magical_hosts"
    @m = @a.field_manager
  end

  it "should be able to lookup entire hash" do
    rv = @m.lookup("*")
    rv.keys.include?("hash").should be_true
    Hash.should === rv["hash"]
    rv.keys.include?("key").should be_true
    rv["key"].should == "value"
  end

  it "should lookup keys by string" do
    @m.lookup("key").should eql("value")
  end

  it "should lookup keys by symbol" do
    @m.lookup(:key).should eql("value")
  end

  it "should lookup hash" do
    @m.lookup(:hash)["leafkey"].should eql("leafvalue")
  end

  it "should lookup leaves" do
    @m.lookup("hash#leafkey").should eql("leafvalue")
    @m.lookup("hash#branchkey#deepleafkey").should eql("deepleafvalue")
  end

  it "should have aliased lookup into the interpreter" do
    @m.object_id.should == @m.interpreter.field_manager.object_id
    @m[:yaml].object_id.should == @m.interpreter.field_manager[:yaml].object_id
  end

  it "should be aliases into the interpreter" do
    @a.lookup("hash#leafkey").should == "leafvalue"
  end
end

describe AutomateIt::FieldManager::Struct do
  it_should_behave_like "AutomateIt::FieldManager"

  before(:all) do
    @m.setup(:default => :struct, :struct => {
      "key" => "value",
      "hash" => {
        "leafkey" => "leafvalue",
        "branchkey" => {
          "deepleafkey" => "deepleafvalue",
        },
      },
    })
  end
end

describe AutomateIt::FieldManager::YAML do
  it_should_behave_like "AutomateIt::FieldManager"

  before(:all) do
    @m[:yaml].should_receive(:_read).with("demo.yml").and_return(<<-EOB)
      <%="key"%>: value
      hash:
        leafkey: leafvalue
        branchkey:
          deepleafkey: deepleafvalue
      magical: <%= tagged?("magical_hosts") ? true : false %>
    EOB
    @m.setup(:default => :yaml, :file => "demo.yml")
  end

  it "should expose the interpreter to ERB statements" do
    @a.lookup("magical").should be_true
  end
end
