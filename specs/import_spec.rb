require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "piston"
require "piston/command"
require "piston/commands/import"

context "import with a valid repository URL" do
  include PistonCommandsHelper

  context_setup do
    @remote_repos = Repository.new
    @rwc = WorkingCopy.new(@remote_repos)
    @rwc.checkout
    @rwc.mkdir("/trunk")

    @rwc.add("/trunk/README", "this is line 1")
    @rwc.commit

    @rwc.add("/trunk/main.c", "int main() { return 0; }")
    @rwc.commit

    @local_repos = Repository.new
    @lwc = WorkingCopy.new(@local_repos)
    @lwc.checkout
  end

  setup do
    import([@remote_repos.url + "/trunk", @lwc.path + "/vendor"])
  end

  teardown do
    @lwc.destroy
    @lwc.checkout
  end

  context_teardown do
    @lwc.destroy
    @local_repos.destroy
    @rwc.destroy
    @remote_repos.destroy
  end

  specify "gets the fulltext of all files" do
    @lwc.cat("/vendor/main.c").should == "int main() { return 0; }"
  end

  specify "remembers the root of the import" do
    @lwc.propget(Piston::ROOT, "vendor").should == @remote_repos.url + "/trunk"
  end

  specify "remembers the upstream repository's UUID" do
    @lwc.propget(Piston::UUID, "vendor").should == @remote_repos.uuid
  end

  specify "remembers the revision we imported from" do
    @lwc.propget(Piston::REMOTE_REV, "vendor").to_i.should == 2
  end

  specify "remembers the revision this WC was at when we imported" do
    @lwc.propget(Piston::LOCAL_REV, "vendor").to_i.should == 0
  end
end
