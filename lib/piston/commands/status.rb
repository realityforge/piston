require "piston"
require "piston/command"
require 'pp'

module Piston
  module Commands
    class Status < Piston::Command
      def run
        # First, find the list of pistoned folders
        folders = svn(:propget, '--recursive', Piston::ROOT, *args)
        repos = Hash.new
        repo = nil
        folders.each_line do |line|
          next unless line =~ /(\w.*) - /
          repos[$1] = Hash.new
        end

        # Then, get their properties
        repo = nil
        svn(:proplist, '--verbose', *repos.keys).each_line do |line|
          case line
          when /'([^']+)'/
            repo = repos[$1]
          when /(piston:[-\w]+)\s*:\s*(.*)$/
            repo[$1] = $2
          end
        end

        # Determine their local status
        repos.each_pair do |path, props|
          log = svn(:log, '--revision', "#{props[Piston::LOCAL_REV]}:HEAD", '--quiet', '--limit', '2', path)
          props[:locally_modified] = 'M' if log.count("\n") > 3
        end

        # And their remote status, if required
        repos.each_pair do |path, props|
          log = svn(:log, '--revision', "#{props[Piston::REMOTE_REV]}:HEAD", '--quiet', '--limit', '2', props[Piston::ROOT])
          props[:remotely_modified] = 'M' if log.count("\n") > 3
        end if show_updates

        # Display the results
        repos.each_pair do |path, props|
          logging_stream.printf "%1s%1s    %5s %s (%s)\n", props[:locally_modified],
              props[:remotely_modified], props[Piston::LOCKED], path, props[Piston::ROOT]
        end

        logging_stream.puts "No pistoned folders found" if repos.empty?
      end

      def self.help
        "Determines the current status of each pistoned directory"
      end

      def self.detailed_help
        <<EOF
usage: status [DIR [DIR...]]

  Shows the status of one, many or all pistoned folders.  The status is
  returned in columns.

  The first column's values are:
     :  Locally unchanged (space)
    M:  Locally modified since importing

  The second column's values are blanks, unless the --show-updates is passed.
    M:  Remotely modified since importing
EOF
      end

      def self.aliases
        %w(st)
      end
    end
  end
end
