require "digest/md5"
require "yaml"
require "tmpdir"
require "tempfile"

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.uniq!

module SubversionClient
  class SubversionCommandFailure < StandardError
    def initialize(command, args, result)
      @command, @args, @result = command, args, result
    end

    def message
      "#{@command} #{@args.join(' ')} resulted in:\n#{@result}"
    end
  end

  def svn(*args)
    run(:svn, args)
  end

  def svnlook(*args)
    run(:svnlook, args)
  end

  def svnadmin(*args)
    run(:svnadmin, args)
  end

  protected
  def run(command, *args)
    args.flatten!
    args.collect! do |arg|
      arg =~ /\s/ ? %Q("#{arg}") : arg
    end

    #puts "#{command} #{args.join(' ')}"
    rval = `#{command} #{args.join(' ')}`
    #puts rval
    raise SubversionCommandFailure.new(command, args, rval) unless $?.success?

    rval
  end
end

class Repository
  include SubversionClient
  attr_reader :name, :path

  def initialize(name=Digest::MD5.hexdigest(Time.now.to_i.to_s))
    @name = name
    @path = File.expand_path(File.join(Dir.tmpdir, "piston", "repositories", @name))
    FileUtils.mkdir_p(File.dirname(@path))
    svnadmin(:create, @path)
  end

  def uuid
    svnlook(:uuid, @path).chomp
  end

  def head_revision
    svnlook(:youngest, @path).chomp.to_i
  end

  def url
    "file://#{path}"
  end

  def destroy
    FileUtils.rm_rf(path)
  end

  def cat(uri)
    svn(:cat, [url.gsub(%r(/$), ''), uri].join("/"))
  end
end

class WorkingCopy
  include SubversionClient
  attr_reader :name, :path, :repository

  def initialize(repository, name=Digest::MD5.hexdigest(Time.now.to_i.to_s))
    @repository, @name = repository, name
    @path = File.expand_path(File.join(Dir.tmpdir, "piston", "working-copies", @name))
    FileUtils.mkdir_p(File.dirname(@path))
  end

  def checkout
    svn(:checkout, repository.url, @path)
  end

  def mkdir(dirname)
    svn(:mkdir, wc_path(dirname))
  end

  def add(filename, content=nil)
    File.open(wc_path(filename), "wb") do |f|
      f.write(content) if content
    end

    svn(:add, wc_path(filename))
  end

  def change(filename, content)
    File.open(wc_path(filename), "wb") do |f|
      f.write(content || "")
    end
  end

  def commit(msg=nil)
    Tempfile.open("svn-commit") do |f|
      f.write(msg) if msg
      f.close
      svn(:commit, "--file", f.path, path)
    end
  end

  def destroy
    FileUtils.rm_rf(path)
  end

  def propget(prop_name, target)
    svn(:propget, prop_name, wc_path(target)).chomp
  end

  def propset(prop_name, value, *targets)
    svn(:propset, prop_name, value, targets.map {|target| wc_path(target)})
  end

  def update(subdir=".")
    svn(:update, wc_path(subdir))
  end

  def info(path=".")
    YAML.load(svn(:info, wc_path(path)))
  end

  def status(*args)
    svn(:status, args, @path).chomp
  end

  def revert(*args)
    svn(:revert, args, @path).chomp
  end

  def cat(filename)
    File.read(wc_path(filename))
  end

  def copy(from, to)
    svn(:copy, wc_path(from), wc_path(to))
  end

  def wc_path(filename=".")
    File.expand_path(File.join(@path, filename))
  end
end

module PistonCommandsHelper
  %w(convert import update switch).each do |command|
    module_eval <<-EOF
      def #{command}(*args)
        options = args.last.kind_of?(Hash) ? args.pop : Hash.new
        StringIO.open(@stream = "") do |io|
          @command = Piston::Commands::#{command.capitalize}.new([args].flatten, options)
          @command.logging_stream = io
          @command.run
        end

        puts @stream if options[:verbose]
      end
    EOF
  end
end
