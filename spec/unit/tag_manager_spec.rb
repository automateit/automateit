require File.join(File.dirname(File.expand_path(__FILE__)), "/../spec_helper.rb")

def prepare_for_tagmanager
  @a = AutomateIt.new
  @a.address_manager.should_receive(:hostnames).any_number_of_times.and_return(["kurou", "kurou.foo"])
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

describe "AutomateIt::TagManager", :shared => true do
  it "should have tags" do
    @a.tags.should be_a_kind_of(Enumerable)
  end

  it "should have tags that include tag for hostname" do
    @a.tags.should include("kurou")
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

  it "should find tags with dashes in the name" do
    tag_with_dash = "pawafuru-mirakuru"
    tag_without_dash = "wandafuru"

    @a.tags << tag_with_dash << tag_without_dash

    @a.tagged?(tag_with_dash).should be_true
    @a.tagged?(tag_without_dash).should be_true
  end

  it "should find tags for a host using an array" do
    @a.tags_for(["kurou"]).should include("apache_servers")
  end

  it "should find tags for a host using a string" do
    @a.tags_for("akane.foo.bar").should include("proxy_servers")
  end

  it "should find hosts with a tag" do
    hosts = @a.hosts_tagged_with("apache_servers")
    hosts.should include("kurou")
    hosts.should include("shirou")
    hosts.should_not include("akane")
  end

  it "should find using negative queries" do
    @a.tagged?("akane").should be_false
    @a.tagged?("!akane").should be_true
    @a.tagged?("!akane && !proxy_servers").should be_true
  end

  it "should include group aliases" do
    @a.hosts_tagged_with("all_servers").sort.should == ["kurou", "shirou", "akane.foo"].sort
  end

  it "should exclude hosts from groups" do
    @a.hosts_tagged_with("apache_servers_except_kurou").should == ["shirou"]
  end

  it "should exclude groups from groups" do
    @a.hosts_tagged_with("all_servers_except_proxy_servers").sort.should == ["kurou", "shirou"].sort
  end

  it "should match tags with dashes" do
    @a.tagged?("apache-servers-using-dashes").should be_true
  end

  it "should include groups with dashes" do
    @a.tagged?("apache-servers-using-dashes-include").should be_true
  end
end

describe "AutomateIt::TagManager::Struct" do
  it_should_behave_like "AutomateIt::TagManager"

  before(:all) do
    prepare_for_tagmanager

    @m.setup(
      :default => :struct,
      :struct => {
        "apache_servers" => [
          "kurou",
          "shirou",
        ],
        "proxy_servers" => [
          "akane.foo",
        ],
        "all_servers" => [
          "@apache_servers",
          "@proxy_servers",
        ],
        "apache_servers_except_kurou" => [
          "@apache_servers",
          "!kurou",
        ],
        "all_servers_except_proxy_servers" => [
          "@all_servers",
          "!@proxy_servers",
        ],
        "apache-servers-using-dashes" => [
          "@apache_servers",
        ],
        "apache-servers-using-dashes-include" => [
          "@apache-servers-using-dashes",
        ]
      }
    )
  end
end

describe "AutomateIt::TagManager::YAML" do
  it_should_behave_like "AutomateIt::TagManager"

  def setup_yaml_tags
    @m[:yaml].should_receive(:_read).any_number_of_times.with("demo.yml").and_return(<<-EOB)
      <%="apache_servers"%>:
        - kurou
        - shirou
      proxy_servers:
        - akane.foo
      all_servers:
        - @apache_servers
        - @proxy_servers
      apache_servers_except_kurou:
        - @apache_servers
        - !kurou
      all_servers_except_proxy_servers:
        - @all_servers
        - !@proxy_servers
      apache-servers-using-dashes:
        - @apache_servers
      apache-servers-using-dashes-include:
        - @apache-servers-using-dashes
    EOB
    @m.setup(
      :default => :yaml,
      :file => "demo.yml"
    )
  end

  before(:all) do
    prepare_for_tagmanager
    setup_yaml_tags
  end

  it "should not clear tags if re-loaded" do
    setup_yaml_tags
    tag = "al-azif"

    @a.tags << tag
    @a.should be_tagged(tag)

    setup_yaml_tags
    @a.should be_tagged(tag)
  end
end

describe "AutomateIt::TagManager::YAML", "with empty struct" do
  def setup_yaml_tags
    @m[:yaml].should_receive(:_read).any_number_of_times.with("demo.yml").and_return(<<-EOB)
      # Empty!
    EOB
    @m.setup(
      :default => :yaml,
      :file => "demo.yml"
    )
  end
  before(:all) do
    prepare_for_tagmanager
    setup_yaml_tags
  end

  it "should tolerate empty struct" do
    @a.tagged?("foo").should be_false
  end
end


describe "AutomateIt::TagManager::YAML", "with no leaves" do
  def setup_yaml_tags
    @m[:yaml].should_receive(:_read).any_number_of_times.with("demo.yml").and_return(<<-EOB)
      <%="apache_servers"%>:
    EOB
    @m.setup(
      :default => :yaml,
      :file => "demo.yml"
    )
  end
  before(:all) do
    prepare_for_tagmanager
    setup_yaml_tags
  end

  it "should tolerate empty leaves" do
    @a.tagged?("apache_servers").should be_false
  end
end

