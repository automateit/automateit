require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::TagManager" do
  before(:each) do
    @a = AutomateIt.new
    @a.platform_manager.setup(
      :default => :struct,
      :struct => {
        :os => "mizrahi",
        :arch => "realian",
        :distro => "momo",
        :version => "s100",
      }
    )
    @m = @a.tag_manager
    @m.setup(
      :hostname_aliases => ["kurou", "kurou.foo"],
      :default => :struct,
      :struct => {
        "apache_servers" => [
          "kurou",
          "shirou",
        ],
        "proxy_servers" => [
          "akane.foo",
        ],
      }
    )
  end

  it "should have tags" do
    @a.tags.is_a?(Enumerable).should be_true
  end

  it "should have tags that include tag for hostname" do
    @a.tags.include?("kurou")
  end

  it "should have tag for short hostname" do
    @a.tagged?("kurou").should be_true
  end

  it "should have tag for long hostname" do
    @a.tagged?("kurou.foo").should be_true
  end

  it "should have tag for OS" do
    @a.tagged?("mizrahi").should be_true
  end

  it "should have tag for OS/arch" do
    @a.tagged?("mizrahi_realian").should be_true
  end

  it "should have tag for distro/release" do
    @a.tagged?("momo_s100").should be_true
  end

  it "should have tag for a role" do
    @a.tagged?("apache_servers").should be_true
  end

  it "should match a symbol query" do
    @a.tagged?(:apache_servers).should be_true
  end

  it "should match a string query" do
    @a.tagged?("apache_servers").should be_true
  end

  it "should not match unknown symbol keys" do
    @a.tagged?(:foo).should be_false
  end

  it "should not match unknown string keys" do
    @a.tagged?("foo").should be_false
  end

  it "should match an AND query" do
    @a.tagged?("kurou && apache_servers").should be_true
  end

  it "should match an OR query" do
    @a.tagged?("kurou || apache_servers").should be_true
  end

  it "should match a grouped AND and OR query" do
    @a.tagged?("(kurou || apache_servers) && momo_s100").should be_true
  end

  it "should not match AND with unknown keys" do
    @a.tagged?("kurou && foo").should be_false
  end

  it "should not match OR with unknown keys" do
    @a.tagged?("foo && bar").should be_false
  end

  # FIXME add tests for @group and !negation

end
