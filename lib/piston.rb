# Copyright (c) 2006 Francois Beausoleil <francois@teksol.info>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# $HeadURL: svn+ssh://rubyforge.org/var/svn/piston/tags/1.4.0/lib/piston.rb $
# $Id: piston.rb 139 2008-02-07 15:28:24Z fbos $

require 'yaml'
require 'uri'
require 'fileutils'

PISTON_ROOT = File.dirname(__FILE__)
Dir[File.join(PISTON_ROOT, 'core_ext', '*.rb')].each do |file|
  require file
end

require "piston/version"
require "piston/command"
require "piston/command_error"

require "transat/parser"
Dir[File.join(PISTON_ROOT, "piston", "commands", "*.rb")].each do |file|
  require file.gsub(PISTON_ROOT, "")[1..-4]
end

module Piston
  ROOT        = "piston:root"
  UUID        = "piston:uuid"
  REMOTE_REV  = "piston:remote-revision"
  LOCAL_REV   = "piston:local-revision"
  LOCKED      = "piston:locked"
end

PistonCommandLineProcessor = Transat::Parser.new do
  program_name "Piston"
  version [Piston::VERSION::STRING]

  option :verbose, :short => :v, :default => true, :message => "Show subversion commands and results as they are executed"
  option :quiet, :short => :q, :default => false, :message => "Do not output any messages except errors"
  option :revision, :short => :r, :param_name => "REVISION", :type => :int
  option :show_updates, :short => :u, :message => "Query the remote repository for out of dateness information"
  option :lock, :short => :l, :message => "Close down and lock the imported directory from further changes"
  option :dry_run, :message => "Does not actually execute any commands"
  option :force, :message => "Force the command to run, even if Piston thinks it would cause a problem"

  command :switch, Piston::Commands::Switch, :valid_options => %w(lock dry_run force revision quiet verbose)
  command :update, Piston::Commands::Update, :valid_options => %w(lock dry_run force revision quiet verbose)
  command :diff,   Piston::Commands::Diff,   :valid_options => %w(lock dry_run force revision quiet verbose)
  command :import, Piston::Commands::Import, :valid_options => %w(lock dry_run force revision quiet verbose)
  command :convert, Piston::Commands::Convert, :valid_options => %w(lock verbose dry_run)
  command :unlock, Piston::Commands::Unlock, :valid_options => %w(force dry_run verbose)
  command :lock, Piston::Commands::Lock, :valid_options => %w(force dry_run revision verbose)
  command :status, Piston::Commands::Status, :valid_options => %w(show_updates verbose)
end
