require "piston"
require "piston/command"

module Piston
  module Commands
    class Import < Piston::Command
      def run
        raise Piston::CommandError, "Missing REPOS_URL argument" if args.empty?

        repos, dir = args.shift, args.shift
        raise Piston::CommandError, "Too many arguments" unless args.empty?
        dir = File.basename(URI.parse(repos).path) unless dir

        if File.exists?(dir) then
          raise Piston::CommandError, "Target folder already exists" unless force
          svn :revert, '--recursive', dir
          FileUtils.rm_rf(dir)
        end

        my_info = YAML::load(svn(:info, File.join(dir, '..')))
        my_revision = YAML::load(svn(:info, my_info['URL']))['Revision']
        raise Piston::CommandError, "#{File.expand_path(File.join(dir, '..'))} is out of date - run svn update" unless my_info['Revision'] == my_revision

        info = YAML::load(svn(:info, repos))
        his_revision = revision || info['Revision']
        options = [:export]
        options << ['--revision', his_revision] 
        options << '--quiet'
        options << repos
        options << dir
        export = svn options
        export.each_line do |line|
          next unless line =~ /Exported revision (\d+)./i
          @revision = $1
          break
        end

        # Add so we can set properties
        svn :add, '--non-recursive', '--force', '--quiet', dir

        # Set the properties
        svn :propset, Piston::ROOT, repos, dir
        svn :propset, Piston::UUID, info['Repository UUID'], dir
        svn :propset, Piston::REMOTE_REV, his_revision, dir
        svn :propset, Piston::LOCAL_REV, my_revision, dir
        svn :propset, Piston::LOCKED, revision, dir if lock

        # Finish adding.  If we get an error, at least the properties will be
        # set and the user can handle the rest
        svn :add, '--force', '--quiet', dir

        logging_stream.puts "Exported r#{his_revision} from '#{repos}' to '#{dir}'"
      end

      def self.help
        "Prepares a folder for merge tracking"
      end

      def self.detailed_help
        <<EOF
usage: import REPOS_URL [DIR]

  Exports the specified REPOS_URL (which must be a Subversion repository) to
  DIR, defaulting to the last component of REPOS_URL if DIR is not present.

  If the local folder already exists, this command will abort with an error.
EOF
      end

      def self.aliases
        %w(init)
      end
    end
  end
end
