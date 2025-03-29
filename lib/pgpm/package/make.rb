# frozen_string_literal: true

module Pgpm
  class Package
    module Make
      def build_steps
        [Pgpm::Commands::Make.new("PG_CONFIG=$PG_CONFIG")] if makefile_present?
      end

      def install_steps
        return unless makefile_present?

        [Pgpm::Commands::Make.new("install", "DESTDIR=$PGPM_INSTALL_ROOT", "PG_CONFIG=$PG_CONFIG")]
      end

      def makefile_present?
        !Dir.glob(%w[Makefile GNUmakefile makefile], base: source.to_s).empty?
      end
    end
  end
end
