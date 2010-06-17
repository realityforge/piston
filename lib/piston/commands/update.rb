require "piston"
require "piston/command"
require 'find'

module Piston
  module Commands
    class Update < Piston::Command
      def run
        (args.empty? ? find_targets : args).each do |dir|
          update dir
        end
      end

      def update(dir)
        return unless File.directory?(dir)
        return skip(dir, "locked") unless svn(:propget, Piston::LOCKED, dir) == ''
        status = svn(:status, '--show-updates', dir)
        new_local_rev = nil
        new_status = Array.new
        status.each_line do |line|
          if line =~ /status.+\s(\d+)$/i then
            new_local_rev = $1.to_i
          else
            new_status << line unless line =~ /^\?/
          end
        end
        raise "Unable to parse status\n#{status}" unless new_local_rev
        return skip(dir, "pending updates -- run \"svn update #{dir}\"\n#{new_status}") if new_status.size > 0

        logging_stream.puts "Processing '#{dir}'..."
        repos = svn(:propget, Piston::ROOT, dir).chomp
        uuid = svn(:propget, Piston::UUID, dir).chomp
        remote_revision = svn(:propget, Piston::REMOTE_REV, dir).chomp.to_i
        local_revision = svn(:propget, Piston::LOCAL_REV, dir).chomp.to_i
        local_revision = local_revision.succ

        logging_stream.puts "  Fetching remote repository's latest revision and UUID"
        info = YAML::load(svn(:info, repos))
        return skip(dir, "Repository UUID changed\n  Expected #{uuid}\n  Found    #{info['Repository UUID']}\n  Repository: #{repos}") unless uuid == info['Repository UUID']

        new_remote_rev = info['Last Changed Rev'].to_i
        return skip(dir, "unchanged from revision #{remote_revision}", false) if remote_revision == new_remote_rev

        revisions = (remote_revision .. (revision || new_remote_rev))

        logging_stream.puts "  Restoring remote repository to known state at r#{revisions.first}"
        svn :checkout, '--ignore-externals', '--quiet', '--revision', revisions.first, repos, dir.tmp

        logging_stream.puts "  Updating remote repository to r#{revisions.last}"
        updates = svn :update, '--ignore-externals', '--revision', revisions.last, dir.tmp

        logging_stream.puts "  Processing adds/deletes"
        merges = Array.new
        changes = 0
        updates.each_line do |line|
          next unless line =~ %r{^([A-Z]).*\s+#{Regexp.escape(dir.tmp)}[\\/](.+)$}
          op, file = $1, $2
          changes += 1

          case op
          when 'A'
            if File.directory?(File.join(dir.tmp, file)) then
              svn :mkdir, '--quiet', File.join(dir, file)
            else
              copy(dir, file)
              svn :add, '--quiet', '--force', File.join(dir, file)
            end
          when 'D'
            svn :remove, '--quiet', '--force', File.join(dir, file)
          else
            copy(dir, file)
            merges << file
          end
        end

        # Determine if there are any local changes in the pistoned directory
        log = svn(:log, '--quiet', '--revision', (local_revision .. new_local_rev).to_svn, '--limit', '2', dir)

        # If none, we skip the merge process
        if local_revision < new_local_rev && log.count("\n") > 3 then
          logging_stream.puts "  Merging local changes back in"
          merges.each do |file|
            begin
              svn(:merge, '--quiet', '--revision', (local_revision .. new_local_rev).to_svn,
                  File.join(dir, file), File.join(dir, file))
            rescue RuntimeError
              next if $!.message =~ /Unable to find repository location for/
            end
          end
        end

        logging_stream.puts "  Removing temporary files / folders"
        FileUtils.rm_rf dir.tmp

        logging_stream.puts "  Updating Piston properties"
        svn :propset, Piston::REMOTE_REV, revisions.last, dir
        svn :propset, Piston::LOCAL_REV, new_local_rev, dir
        svn :propset, Piston::LOCKED, revisions.last, dir if lock

        logging_stream.puts "  Updated to r#{revisions.last} (#{changes} changes)"
      end

      def copy(dir, file)
        FileUtils.cp(File.join(dir.tmp, file), File.join(dir, file))
      end

      def self.help
        "Updates all or specified folders to the latest revision"
      end

      def self.detailed_help
        <<EOF
usage: update [DIR [...]]

  This operation has the effect of downloading all remote changes back to our
  working copy.  If any local modifications were done, they will be preserved.
  If merge conflicts occur, they will not be taken care of, and your subsequent
  commit will fail.

  Piston will refuse to update a folder if it has pending updates.  Run
  'svn update' on the target folder to update it before running Piston
  again.
EOF
      end

      def self.aliases
        %w(up)
      end
    end
  end
end
