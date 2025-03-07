# frozen_string_literal: true

require "digest"
require "open-uri"
require "erb"

module Pgpm
  module Deb
    class Spec
      attr_reader :package, :release, :postgres_version, :postgres_distribution

      def initialize(package)
        @package = package
        @release = 1

        @postgres_distribution = Pgpm::Postgres::Distribution.in_scope
      end

      def sources
        @package.sources
      end

      def generate(template_name)
        fn = "#{__dir__}/templates/#{template_name}.erb"
        raise "No such template: #{fn}" unless File.exist?(fn)
        erb = ERB.new(File.read(fn))
        erb.result(binding)
      end

      def deps
        ["postgresql-#{postgres_major_version}"]
      end

      def build_deps
        [
          "postgresql-#{postgres_major_version}",
          "build-essential",
          "postgresql-#{postgres_major_version}",
          "postgresql-server-dev-#{postgres_major_version}",
          "postgresql-common"
        ]
      end

      def postgres_major_version
        self.postgres_distribution.version.split(".")[0]
      end

      def source_version
        @package.version.to_s
      end

      def full_pkg_name
        "#{@package.name}-#{@package.version.to_s}_0-1_#{arch}"
      end

      def arch
        # https://memgraph.com/blog/ship-it-on-arm64-or-is-it-aarch64
        # Debian suffixes are "amd64" and "arm64". Here we translate:
        case Pgpm::Arch.host.name
          when "amd64", "x86_64"
            "amd64"
          when "aarch64", "arm64"
            "arm64"
        end
      end

      # Whatever is returned from this method gets added to the "rules" file.
      def rules_amendments
        "#"
      end

    end
  end
end
