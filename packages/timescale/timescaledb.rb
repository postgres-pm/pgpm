# frozen_string_literal: true

module Timescale
  class Timescaledb < Pgpm::Package
    github "timescale/timescaledb"

    def self.package_versions
      # TODO: ensure non-compatible versions are handled better
      # in version comparison
      # For now, this helps with handling `loader-2.11.0p1` version
      super.select { |v| v.to_s =~ /^(\d+\.\d+\.\d+)$/ }
    end

    def description
      "An open-source time-series SQL database optimized for fast ingest and " \
        "complex queries"
    end

    def summary
      "TimescaleDB is an open-source database designed to make SQL "        \
        "scalable for time-series data. It is engineered up from PostgreSQL " \
        "and packaged as a PostgreSQL extension, providing automatic "        \
        "partitioning across time and space (partitioning key), as well as "  \
        "full SQL support."
    end

    def dependencies
      deps = case Pgpm::OS.in_scope.class.name
             when "rocky+epel-9", "redhat", "fedora"
               ["openssl"]
             end
      super + deps
    end

    def build_dependencies
      deps = case Pgpm::OS.in_scope.class.name
             when "debian", "ubuntu"
               %w[libssl-dev cmake]
             when "rocky+epel-9", "redhat", "fedora"
               %w[openssl-devel cmake]
             end
      super + deps
    end

    def configure_steps
      case Pgpm::OS.in_scope.class.name
      when "debian", "ubuntu"
        ["dh_auto_configure -- -DCMAKE_BUILD_TYPE=\"Release\""]
      else
        super
      end
    end

    def build_steps
      case Pgpm::OS.in_scope.class.name
      when "debian", "ubuntu"
        ["dh_auto_build"]
      when "rocky+epel-9", "redhat", "fedora"
        [
          "./bootstrap -DPG_CONFIG=$PG_CONFIG #{bootstrap_flags.map { |f| "-D#{f}" }.join(" ")}",
          "cmake --build build --parallel"
        ]
      end
    end

    def install_steps
      case Pgpm::OS.in_scope.class.name
      when "rocky+epel-9", "redhat", "fedora"
        ["DESTDIR=$PGPM_INSTALL_ROOT cmake --build build --target install"]
      else
        super
      end
    end

    protected

    def bootstrap_flags
      []
    end
  end
end
