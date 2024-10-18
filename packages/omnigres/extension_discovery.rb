# frozen_string_literal: true

require "git"
require "parallel"

module Omnigres
  class ExtensionDiscovery
    @@extensions = {}
    @@git_revisions = {}

    def initialize(revision: nil, path: nil)
      return if @@extensions[revision]

      suffix = revision ? "-#{revision}" : nil
      path ||= Pgpm::Cache.directory.join("omnigres#{suffix}")
      git =
        if File.directory?(path)
          ::Git.open(path)
        else
          ::Git.clone("https://github.com/omnigres/omnigres", path)
        end
      git.checkout(revision) if revision
      @git = git
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

      merges = @git.log(:all).select { |c| c.parents.size > 1 }
      commit_merges = Hash[Parallel.flat_map(merges) do |m|
        before = m.parents[0].sha
        after = m.parents[1].sha
        commits = git.log.between(before, after).map(&:sha)
        commits.product([m.sha])
      end]

      versions_maps = @git.log(:all).path("versions.txt").flat_map do |c|
        Hash[@git.show(c,
                       "versions.txt").split("\n").map do |l|
               ext, ver = l.split("=")
               [[ext, c.sha], Pgpm::Package::Version.new(ver)]
             end]
      end
      extensions = versions_maps.flat_map(&:keys).map(&:first).uniq
      @@extensions[@git.log.first.sha] = Hash[extensions.map do |e|
        [e, versions_maps.map do |m|
          m.transform_keys(&:first)[e]
        end.compact.uniq.sort]
      end]
      last_hashes = Hash[versions_maps.flat_map do |h|
        h.each_pair.map { |(ext, sha), ver| [[ext, ver], sha] }
      end]
      @@git_revisions[@git.log.first.sha] = last_hashes.each_with_object({}) do |((name, version), sha), result|
        result[name] ||= {}
        result[name][version] = commit_merges[sha]
      end.transform_values { |versions| versions.uniq { |_version, merge| merge }.to_h } # Filter out versions that were historical part of the merge
      @@extensions[@git.log.first.sha] = @@extensions[@git.log.first.sha].map { |name, versions| [name, versions.filter { |v| @@git_revisions[@git.log.first.sha][name].include?(v) }] }.to_h
    end
  end
end
