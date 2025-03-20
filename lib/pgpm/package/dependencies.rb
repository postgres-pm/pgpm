# frozen_string_literal: true

module Pgpm
  class Package
    module Dependencies

      attr_accessor :postgres_major_version

      def build_dependencies
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          [
            "postgresql-#{postgres_major_version}",
            "postgresql-server-dev-#{postgres_major_version}",
            "postgresql-common"
          ]
        when "rocky+epel-9", "redhat", "fedora"
          [
            "postgresql-#{postgres_major_version}",
            "postgresql-server-devel-#{postgres_major_version}",
            "postgresql-common"
          ]
        end
      end

      def dependencies
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          [ "postgresql-#{postgres_major_version}" ]
        when "rocky+epel-9", "redhat", "fedora"
          [ "postgresql-#{postgres_major_version}" ]
        end
      end

      def requires
        []
      end

      def all_requirements
        requires.flat_map { |r| [r, *r.all_requirements] }.uniq
      end

      def c_files_present?
        Dir.glob("*.c", base: source).any?
      end

    end
  end
end
