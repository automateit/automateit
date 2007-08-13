require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

describe "AutomateIt::TagManager", :shared => true do
  before(:all) do
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

  it "should query tags for a specific host" do
    @a.tagged?("proxy_servers", "kurou").should be_false
    @a.tagged?("proxy_servers", "akane.foo").should be_true
    @a.tagged?("proxy_servers", "akane").should be_true
  end

  it "should append tags" do
    @a.tagged?("magic").should be_false
    @a.tags << "magic"
    @a.tagged?("magic").should be_true
  end

  it "should find hostname aliases" do
    hostnames = @a.hostname_aliases_for("kurou.foo.bar")
    hostnames.include?("kurou.foo.bar").should be_true
    hostnames.include?("kurou.foo").should be_true
    hostnames.include?("kurou").should be_true
  end

  it "should find tags for a host using an array" do
    @a.tags_for(["kurou"]).include?("apache_servers").should be_true
  end

  it "should find tags for a host using a string" do
    @a.tags_for("akane.foo.bar").include?("proxy_servers").should be_true
  end

  it "should find hosts with a tag" do
    hosts = @a.hosts_tagged_with("apache_servers")
    hosts.include?("kurou").should be_true
    hosts.include?("shirou").should be_true
    hosts.include?("akane").should be_false
  end

=begin
  it "should find using negative queries" do
    # TODO fails because single word queries aren't tokenized
    @a.tagged?("akane").should be_false
    @a.tagged?("!akane").should be_true
  end

  # FIXME add tests for @group and !negation
=end
end

describe "AutomateIt::TagManager::Struct" do
  it_should_behave_like "AutomateIt::TagManager"

  before do
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
end

describe "AutomateIt::TagManager::YAML" do
  it_should_behave_like "AutomateIt::TagManager"

  before do
    @m[:yaml].should_receive(:_read).with("demo.yml").and_return(<<-EOB)
      <%="apache_servers"%>:
        - kurou
        - shirou
      proxy_servers:
        akane.foo
    EOB
    @m.setup(
      :hostname_aliases => ["kurou", "kurou.foo"],
      :default => :yaml,
      :file => "demo.yml"
    )
  end
end
