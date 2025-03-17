# frozen_string_literal: true

require "git"
require "parallel"

module Omnigres
  class ExtensionDiscovery
    @@extensions = {}
    @@git_revisions = {}
    @mutex = Mutex.new

    class << self
      attr_reader :mutex # Expose a class-level reader for the mutex
    end

    def initialize(revision: nil, path: nil)
      return if @@extensions[revision]

      suffix = revision ? "-#{revision}" : nil
      path ||= Pgpm::Cache.directory.join("omnigres#{suffix}")
      self.class.mutex.synchronize do
        git =
          if File.directory?(path)
            g = ::Git.open(path)
            g.pull
            g
          else
            ::Git.clone("https://github.com/omnigres/omnigres", path)
          end
        git.checkout(revision) if revision
        @git = git
      end
    end

    attr_reader :git

    def extension_versions
      process_git_log
      @@extensions[@git.log.first.sha]
    end

    def extension_git_revisions
      process_git_log
      @@git_revisions[@git.log.first.sha]
    end

    private

    def process_git_log
      return if @@extensions[@git.log.first.sha]

      # Direct merge commits into master
      direct_master_merges = @git.lib.send(:command, "rev-list", "master", "--first-parent").split.map

      # Get versions.txt from all direct merges (we don't want to consider what's inside a merge
      # as it may contain versions we never released)
      # This is going to create a hash table [name, sha] => version
      versions_map = @git.log(:all).path("versions.txt").select { |c| direct_master_merges.include?(c.sha) }.each_with_object({}) do |c, h|
        lines = @git.show(c, "versions.txt").split
        lines.each do |l|
          ext, ver = l.split("=")
          h[[ext, c.sha]] = Pgpm::Package::Version.new(ver)
        end
      end

      # Hash mapping extension names to a list of versions
      # name => [versions]
      @@extensions[@git.log.first.sha] = versions_map.group_by { |(name, _sha), _ver| name }
                                                     .transform_values { |entries| entries.map { |_key, version| version }.uniq }

      # Hash mapping extension versions to SHAs
      # [name][ver] => sha
      # Note that we're getting the latest merges that contain this version – it doesn't mean that these
      # are the merges where those versions were introduced. But that's okay because if they are there,
      # they are buildable at least as of those merges and possible at the HEAD of master.
      @@git_revisions[@git.log.first.sha] = versions_map.each_with_object({}) do |((name, sha), version), result|
        result[name] ||= {}
        result[name][version] = sha
      end
    end
  end
end
