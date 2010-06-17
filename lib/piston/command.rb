require "piston"

module Piston
  # The base class which all commands subclass to obtain services from.
  class Command
    attr_accessor :revision, :dry_run, :quiet, :verbose, :force, :lock,
                  :recursive, :show_updates
    attr_reader :args
    attr_writer :logging_stream

    def initialize(non_options, options)
      @args = non_options

      # Because the Windows shell does not process wildcards, we must do it
      # here ourselves
      @args.collect! do |arg|
        next arg unless arg =~ /[*?]/
        Dir[arg]
      end

      options.each do |option, value|
        self.send("#{option}=", value)
      end
    end

    # Run a Subversion command using the shell.  If the Subversion command
    # returns an existstatus different from zero, a RuntimeError is raised.
    def svn(*args)
      args = args.flatten.compact.map do |arg|
        if arg.to_s =~ /[ *?@]/ then
          %Q("#{arg}")
        else
          arg
        end
      end

      command = "svn #{args.join(' ')}"
      logging_stream.puts command if verbose
      return if dry_run
      ENV['LANGUAGE'] = 'en_US'
      result = `#{command}`
      logging_stream.puts result if verbose
      raise "Command #{command} resulted in an error:\n\n#{result}" unless $?.exitstatus.zero?
      result
    end

    # Returns an IO-like object to which all information should be logged.
    def logging_stream
      @logging_stream ||= $stdout
    end

    def skip(dir, msg, header=true)
      logging_stream.print "Skipping '#{dir}': " if header
      logging_stream.puts msg
    end

    def find_targets
      targets = Array.new
      svn(:propget, '--recursive', Piston::ROOT).each_line do |line|
        next unless line =~ /^([^ ]+)\s-\s.*$/
        targets << $1
      end

      targets
    end

  end
end
