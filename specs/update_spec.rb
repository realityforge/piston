require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require "piston"
require "piston/command"
require "piston/commands/update"

context "update when no local changes" do
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

    convert(@lwc.path)
    @lwc.commit

    @rwc.change("/trunk/main.c", "int main() { return 1; }")
    @rwc.commit
  end

  setup do
    update(@lwc.path + "/vendor")
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

  specify "retrieves the latest fulltext from the remote repository" do
    @lwc.cat("/vendor/main.c").should == @remote_repos.cat("/trunk/main.c")
  end

  specify "records remote revision that was merged" do
    @lwc.propget(Piston::REMOTE_REV, "/vendor").should == @remote_repos.head_revision.to_s
  end
end

context "update when a local change" do
  include PistonCommandsHelper

  context_setup do
    @remote_repos = Repository.new
    @rwc = WorkingCopy.new(@remote_repos)
    @rwc.checkout
    @rwc.mkdir("/trunk")

    @rwc.add("/trunk/README", "this is line 1")
    @rwc.commit

    @rwc.add("/trunk/main.c", "int main() {\n  return 0;\n}\n")
    @rwc.commit

    @local_repos = Repository.new
    @lwc = WorkingCopy.new(@local_repos)
    @lwc.checkout

    @lwc.propset("svn:externals", %Q(vendor #{@remote_repos.url + "/trunk"}), ".")
    @lwc.commit
    @lwc.update

    convert(@lwc.path)
    @lwc.commit

    # Make our local change
    # We're adding a new license as the first line
    @lwc.change("/vendor/main.c", "// new license text\n#{@lwc.cat("/vendor/main.c")}")
    @lwc.commit

    @rwc.change("/trunk/main.c", "int main() {\n  return 1;\n}\n")
    @rwc.commit
  end

  setup do
    update(@lwc.path + "/vendor")
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

  specify "should merge local changes with remote ones" do
    @lwc.cat("/vendor/main.c").should == "// new license text\nint main() {\n  return 1;\n}\n"
  end
end
