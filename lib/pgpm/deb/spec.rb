# frozen_string_literal: true

require "digest"
require "open-uri"

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

      def generate_control
      end

      def generate_rules
      end

      def generate_licence
      end

      def generate_version
      end

      private

      def unpack?(src)
        src = src.name if src.respond_to?(:name)
        src.to_s.end_with?(".tar.gz") || src.to_s.end_with?(".tar.xz")
      end

    end
  end
end
