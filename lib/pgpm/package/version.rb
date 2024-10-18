# frozen_string_literal: true

require "semver_dialects"

module Pgpm
  class Package
    class Version
      include Comparable

      def initialize(version)
        recognize_version(version)
        @version_string = version.to_s
      end

      def to_s
        @version_string
      end

      def ==(other)
        to_s == other.to_s
      end

      alias eql? ==

      def <=>(other)
        raise "unsupported version provider" unless @version.is_a?(SemverDialects::BaseVersion)

        @version <=> SemverDialects.parse_version(@semver_type, other.to_s)
      end

      def hash
        to_s.hash
      end

      def satisfies?(range)
        raise "unsupported version provider" unless @version.is_a?(SemverDialects::BaseVersion)

        SemverDialects.version_satisfies?(@semver_type, @version_string, range)
      end

      private

      def recognize_version(version)
        @semver_type, @version = %w[cargo deb rpm].lazy.filter_map do |type|
          [type, SemverDialects.parse_version(type, version)]
        rescue SemverDialects::InvalidVersionError
          nil
        end.first || version
      end
    end
  end
end
