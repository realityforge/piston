require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "piston"
require "piston/command"
require "piston/commands/import"

context "switching to a branch in the same repository (without local mods)" do
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

    @rwc.mkdir("/branches")
    @rwc.copy("/trunk", "/branches/stable")
    @rwc.commit

    @rwc.change("/trunk/main.c", "int main() { /* trunk */ return 0; }")
    @rwc.change("/branches/stable/main.c", "int main() { /* branch */ return 0; }")
    @rwc.commit

    @local_repos = Repository.new
    @lwc = WorkingCopy.new(@local_repos)
    @lwc.checkout

    @lwc.propset("svn:externals", %Q(vendor #{@remote_repos.url + "/trunk"}), ".")
    @lwc.commit
    @lwc.update

    convert(@lwc.path)
    @lwc.commit
    @lwc.update
  end

  setup do
    switch(@remote_repos.url + "/branches/stable", @lwc.path + "/vendor")
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

  specify "gets the fulltext of the branch" do
    @lwc.cat("/vendor/main.c").should == "int main() { /* branch */ return 0; }"
  end

  specify "changes the root of the pistoned dir to the new import location" do
    @lwc.propget(Piston::ROOT, "vendor").should == @remote_repos.url + "/branches/stable"
  end

  specify "keeps the upstream repository's UUID unchanged" do
    @lwc.propget(Piston::UUID, "vendor").should == @remote_repos.uuid
  end

  specify "remembers the upstream revision we pistoned from" do
    @lwc.propget(Piston::REMOTE_REV, "vendor").should == "4"
  end
end
