require "piston"
require "piston/command"
require 'find'

module Piston
  module Commands
    class Diff < Piston::Command
      def run
        (args.empty? ? find_targets : args).each do |dir|
          diff dir
        end
      end

      def diff(dir)
        return unless File.directory?(dir)
        logging_stream.puts "Processing '#{dir}'..."
        repos = svn(:propget, Piston::ROOT, dir).chomp
        uuid = svn(:propget, Piston::UUID, dir).chomp
        remote_revision = svn(:propget, Piston::REMOTE_REV, dir).chomp.to_i

        logging_stream.puts "  Fetching remote repository's latest revision and UUID"
        info = YAML::load(svn(:info, repos))
        return skip(dir, "Repository UUID changed\n  Expected #{uuid}\n  Found    #{info['Repository UUID']}\n  Repository: #{repos}") unless uuid == info['Repository UUID']

        logging_stream.puts "  Checking out repository at revision #{remote_revision}"
        svn :checkout, '--ignore-externals', '--quiet', '--revision', remote_revision, repos, dir.tmp

        puts run_diff(dir.tmp, dir)

        logging_stream.puts "  Removing temporary files / folders"
        FileUtils.rm_rf dir.tmp

      end

      def run_diff(dir1, dir2)
        `diff -urN --exclude=.svn #{dir1} #{dir2}`
      end

      def self.help
        "Shows the differences between the local repository and the pristine upstream"
      end

      def self.detailed_help
        <<EOF
usage: diff [DIR [...]]

  This operation has the effect of producing a diff between the pristine upstream
  (at the last updated revision) and your local version.  In other words, it
  gives you the changes you have made in your repository that have not been
  incorporated upstream.
EOF
      end
    end
  end
end
