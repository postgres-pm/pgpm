# frozen_string_literal: true

module Pgpm
  class Package
    module Make

      def build_steps
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          return []
        when "rocky+epel-9", "redhat", "fedora"
          return [Pgpm::Commands::Make.new("PG_CONFIG=$PG_CONFIG")] if makefile_present?
        end
        super
      end

      def install_steps
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          return []
        when "rocky+epel-9", "redhat", "fedora"
          return [Pgpm::Commands::Make.new("install", "DESTDIR=$PGPM_BUILDROOT", "PG_CONFIG=$PG_CONFIG")] if makefile_present?
        end
        super
      end

      def makefile_present?
        !Dir.glob(%w[Makefile GNUmakefile makefile], base: source.to_s).empty?
      end

    end

  end
end
