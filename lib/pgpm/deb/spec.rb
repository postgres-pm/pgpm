# frozen_string_literal: true

require "digest"
require "open-uri"
require "erb"

module Pgpm
  module Deb
    class Spec
      attr_reader :package, :release, :postgres_version, :postgres_distribution

      def initialize(package)
        @postgres_distribution = Pgpm::Postgres::Distribution.in_scope
        @package = package
        @package.postgres_major_version = @postgres_distribution.major_version
        @release = 1
      end

      def sources
        @package.sources
      end

      def generate(template_name, pkg_type=:versioned)
        fn = "#{__dir__}/templates/#{template_name}.erb"
        raise "No such template: #{fn}" unless File.exist?(fn)
        erb = ERB.new(File.read(fn))

        # Uses pkg_type parameter (which is in scope) to generate
        # debian/* files for versionless and main packages.
        erb.result(binding)
      end

      def source_version
        @package.version.to_s
      end

      def deb_pkg_name(type=:versioned)
        if type == :versioned
          "#{@package.name}+#{@package.version.to_s}-pg#{@package.postgres_major_version}"
        else
          "#{@package.name}-pg#{@package.postgres_major_version}"
        end
      end

      def arch
        # https://memgraph.com/blog/ship-it-on-arm64-or-is-it-aarch64
        # Debian suffixes are "amd64" and "arm64". Here we translate:
        case Pgpm::Arch.in_scope.name
          when "amd64", "x86_64"
            "amd64"
          when "aarch64", "arm64"
            "arm64"
        end
      end

      def cmds_if_not_empty(cmds, else_echo)
        if cmds.nil? || cmds.empty?
          return "\techo \"#{else_echo}\""
        else
          cmds.map! { |c| c.to_s }
          cmds.map! { |c| c.gsub("$", "$$") }
          return cmds.join("\t")
        end
      end

    end
  end
end
