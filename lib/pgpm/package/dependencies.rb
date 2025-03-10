# frozen_string_literal: true

module Pgpm
  class Package
    module Dependencies

      attr_accessor :postgres_major_version

      def build_dependencies
        case @os
        when "debian", "ubuntu"
          [
            "build-essential",
            "postgresql-#{postgres_major_version}",
            "postgresql-server-dev-#{postgres_major_version}",
            "postgresql-common"
          ]
        when "rocky", "redhat", "fedora"
          [
            "build-essential",
            "postgresql-#{postgres_major_version}",
            "postgresql-server-devel-#{postgres_major_version}",
            "postgresql-common"
          ]
        end
      end

      def dependencies
        case @os
        when "debian", "ubuntu"
          [ "postgresql-#{postgres_major_version}" ]
        when "rocky", "redhat", "fedora"
          [ "postgresql-#{postgres_major_version}" ]
        end
      end

      def requires
        []
      end

      def c_files_present?
        Dir.glob("*.c", base: source).any?
      end

    end
  end
end
