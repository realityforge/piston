require "piston"
require "piston/command"

module Piston
  module Commands
    class Unlock < Piston::Command
      def run
        raise Piston::CommandError, "No targets to run against" if args.empty?
        svn :propdel, Piston::LOCKED, *args
        args.each do |dir|
          logging_stream.puts "Unlocked '#{dir}'"
        end
      end

      def self.help
        "Undoes the changes enabled by lock"
      end

      def self.detailed_help
        <<EOF
usage: unlock DIR [DIR [...]]

  Unlocked folders are free to be updated to the latest revision when
  updating.
EOF
      end
    end
  end
end
