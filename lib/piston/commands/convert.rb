require "piston"
require "piston/command"
require "piston/commands/import"

module Piston
  module Commands
    class Convert < Piston::Command
      def run
        if args.empty? then
          svn(:propget, '--recursive', 'svn:externals').each_line do |line|
            next unless line =~ /^([^ ]+)\s-\s/
            args << $1
          end
        end

        return logging_stream.puts("No svn:externals defined in this folder or any of it's subfolders") if args.empty?

        args.each do |dir|
          externals = svn(:propget, 'svn:externals', dir)
          next skip_no_externals(dir) if externals.chomp.empty?

          operations = Array.new
          externals.each_line do |external|
            external.chomp!
            next if external.empty?
            next skip_no_match(external) unless external =~ /^([^ ]+)\s+(?:-r\s*(\d+)\s+)?(.*)$/

            local, revision, repos = $1, $2, $3
            lock = true if revision
            local_dir = File.join(dir, local)
            if File.exists?(local_dir)
              raise Piston::CommandError, "#{local_dir.inspect} is not a directory" unless File.directory?(local_dir)
              status = svn(:status, local_dir)
              raise Piston::CommandError, "#{local_dir.inspect} has local modifications:\n#{status}\nYour must revert or commit before trying again." unless status.empty?
              info = YAML::load(svn(:info, local_dir))
              revision = info['Last Changed Rev'] unless revision
              FileUtils.rm_rf(local_dir)
            end

            operations << [local_dir, revision, repos, lock]
          end

          operations.each do |local_dir, revision, repos, lock|
            logging_stream.puts "Importing '#{repos}' to #{local_dir} (-r #{revision || 'HEAD'}#{' locked' if lock})"
            import = Piston::Commands::Import.new([repos, local_dir], {})
            import.revision = revision
            import.verbose, import.quiet, import.logging_stream =  self.verbose, self.quiet, self.logging_stream
            import.lock = lock
            import.run
            logging_stream.puts
          end
        end

        svn :propdel, 'svn:externals', *args
        logging_stream.puts "Done converting existing svn:externals to Piston"
      end

      def skip_no_externals(dir)
        logging_stream.puts "Skipping '#{dir}' - no svn:externals definition"
      end

      def skip_no_match(external)
        logging_stream.puts "#{external.inspect} did not match Regexp"
      end

      def self.help
        "Converts existing svn:externals into Piston managed folders"
      end

      def self.detailed_help
        <<EOF
usage: convert [DIR [...]]

  Converts folders which have the svn:externals property set to Piston managed 
  folders.
EOF
      end
    end
  end
end
