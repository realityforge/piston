require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "piston"
require "piston/command"
require "piston/commands/convert"

context "convert with no svn:externals" do
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

    @lwc.mkdir("/vendor")
    @lwc.commit
    @lwc.update
  end

  setup do
    convert(@lwc.path + "/vendor")
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

  specify "does not touch the working copy" do
    @lwc.status.should == ""
  end
end

context "convert with one svn:externals" do
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

    @lwc.propset("svn:externals", %Q(vendor #{@remote_repos.url + "/trunk"}), ".")
    @lwc.commit
    @lwc.update
  end

  setup do
    convert(@lwc.path)
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

  specify "removes existing folder to replace with piston export" do
    @lwc.info("/vendor")["Schedule"].should == "add"
    @lwc.info("/vendor")["Revision"].should == 0
  end

  specify "remembers the revision we converted from" do
    @lwc.propget(Piston::REMOTE_REV, "/vendor").should == "2"
  end
end

context "convert with hard-coded revision in svn:externals" do
  include PistonCommandsHelper

  context_setup do
    @remote_repos = Repository.new
    @rwc = WorkingCopy.new(@remote_repos)
    @rwc.checkout

    @rwc.mkdir("/trunk")
    @rwc.add("/trunk/README", "this is line 1")
    @rwc.commit

    @rwc.add("/trunk/main.c", "int main() { /* first */ return 0; }")
    @rwc.commit

    @rwc.change("/trunk/main.c", "int main() { /* second */ return 1; }")
    @rwc.commit

    @local_repos = Repository.new
    @lwc = WorkingCopy.new(@local_repos)
    @lwc.checkout

    @lwc.propset("svn:externals", %Q(vendor -r 2 #{@remote_repos.url + "/trunk"}), ".")
    @lwc.commit
    @lwc.update
  end

  setup do
    convert(@lwc.path)
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

  specify "retrieves the specified revision text" do
    @lwc.cat("/vendor/main.c").should == "int main() { /* first */ return 0; }"
  end

  specify "locks the pistoned directory to that revision" do
    @lwc.propget(Piston::LOCKED, "/vendor").should == "2"
  end
end

context "convert with non HEAD externals" do
  include PistonCommandsHelper

  setup do
    @remote_repos = Repository.new
    @rwc = WorkingCopy.new(@remote_repos)
    @rwc.checkout

    @rwc.mkdir("/trunk")
    @rwc.add("/trunk/README", "this is line 1")
    @rwc.commit

    @rwc.add("/trunk/main.c", "int main() { /* first */ return 0; }")
    @rwc.commit

    @local_repos = Repository.new
    @lwc = WorkingCopy.new(@local_repos)
    @lwc.checkout

    @lwc.propset("svn:externals", %Q(vendor #{@remote_repos.url + "/trunk"}), ".")
    @lwc.commit
    @lwc.update

    @rwc.change("/trunk/main.c", "int main() { /* second */ return 1; }")
    @rwc.commit

    convert(@lwc.path)
  end

  teardown do
    @lwc.destroy
    @local_repos.destroy
    @rwc.destroy
    @remote_repos.destroy
  end

  specify "retrieves the same revision we had in our WC" do
    @lwc.cat("/vendor/main.c").should == "int main() { /* first */ return 0; }"
  end

  specify "remembers the revision that was present, not HEAD" do
    @lwc.propget(Piston::REMOTE_REV, "/vendor").should == "2"
  end

  specify "does not lock the pistoned directory" do
    @lwc.propget(Piston::LOCKED, "/vendor").should be_empty
  end
end
