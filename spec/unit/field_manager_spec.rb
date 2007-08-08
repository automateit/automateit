require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe AutomateIt::FieldManager do
  before do
    @m = AutomateIt::FieldManager.new
    @m.struct = {
      "key" => "value",
      "hash" => {
        "leafkey" => "leafvalue",
        "branchkey" => {
          "deepleafkey" => "deepleafvalue",
        },
      },
    }
  end

  it "should be able to look at raw struct" do
    @m.struct["key"].should eql("value")
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
end
