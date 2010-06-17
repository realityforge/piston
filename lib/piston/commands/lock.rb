require "piston"
require "piston/command"

module Piston
  module Commands
    class Lock < Piston::Command
      def run
        raise Piston::CommandError, "No targets to run against" if args.empty?

        args.each do |dir|
          remote_rev = svn(:propget, Piston::REMOTE_REV, dir).chomp.to_i
          svn :propset, Piston::LOCKED, remote_rev, dir
          logging_stream.puts "'#{dir}' locked at revision #{remote_rev}"
        end
      end

      def self.help
        "Lock one or more folders to their current revision"
      end

      def self.detailed_help
        <<EOF
usage: lock DIR [DIR [...]]

  Locked folders will not be updated to the latest revision when updating.
EOF
      end
    end
  end
end
