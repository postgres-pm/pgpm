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
        ["postgresql-#{postgres_version}"]
      end

      def build_deps
        [
          "postgresql-#{postgres_version}",
          "build-essential",
          "postgresql-#{postgres_version}",
          "postgresql-server-dev-#{postgres_version}",
          "postgresql-common"
        ]
      end

      def postgres_version
        17
      end

      def source_version
        @package.version.to_s
      end

      def source_name
        @package.name
      end

      def full_pkg_name
        "#{@package.name}-#{@package.version.to_s}_0-1_#{arch}"
      end

      def deb_version
        "0.1.0"
      end

      def arch
        "amd64"
      end

      def description
        @package.description
      end

      # Whatever is returned from this method gets added to the "rules" file.
      def rules_amendments
        "#"
      end

    end
  end
end
