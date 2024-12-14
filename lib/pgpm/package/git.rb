# frozen_string_literal: true

require "git"

module Pgpm
  class Package
    module Git
      Config = Data.define(:url, :download_version_tags)

      module ClassMethods
        attr_reader :git_config

        module Methods
          SEMVER = /^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/

          def package_versions
            if !git_config.download_version_tags
              super
            else
              git_term_prompt = ENV["GIT_TERMINAL_PROMPT"]
              ENV["GIT_TERMINAL_PROMPT"] = "0"
              begin
                @tags ||=
                  ::Git.ls_remote(git_config.url)["tags"].keys
                       .filter { |key| !key.end_with?("^{}") }
                       .filter { |key| key.match?(SEMVER) }
              rescue StandardError
                @tags ||= []
              end
              ENV["GIT_TERMINAL_PROMPT"] = git_term_prompt
              versions = @tags.map { |tag| tag.gsub(/^v/, "") }.map { |v| Pgpm::Package::Version.new(v) }
              @tag_versions = Hash[@tags.zip(versions)]
              @version_tags = Hash[versions.zip(@tags)]
              versions
            end
          end
        end

        def git(url, download_version_tags: true)
          @git_config = Config.new(url:, download_version_tags:)
          extend Methods
        end
      end

      def version_git_tag
        self.class.package_versions if self.class.instance_variable_get(:@version_tags).nil?
        version_tags = self.class.instance_variable_get(:@version_tags) || {}
        version_tags[version]
      end

      def version_git_commit
        nil
      end

      def source
        directory = Pgpm::Cache.directory.join(name, version.to_s)
        tag = version_git_tag
        commit = version_git_commit
        directory = Pgpm::Cache.directory.join(name, commit) if commit
        if File.directory?(directory) && File.directory?(directory.join(".git"))
          directory
        elsif File.directory?(directory)
          raise "Unexpected non-git directory #{directory}"
        else
          if tag
            ::Git.clone(self.class.git_config.url, directory, depth: 1, branch: version_git_tag)
          elsif commit
            g = ::Git.clone(self.class.git_config.url, directory)
            g.checkout("checkout-#{commit}", new_branch: true, start_point: commit)
          else
            ::Git.clone(self.class.git_config.url, directory, depth: 1)
          end
          directory
        end
      end

      def release_date
        ::Git.open(source).log.first.date
      end

      def self.included(base_class)
        base_class.extend(ClassMethods)
      end
    end
  end
end
