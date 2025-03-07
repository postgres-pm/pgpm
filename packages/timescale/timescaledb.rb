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

    def summary
      "TimescaleDB is an open-source database designed to make SQL scalable for time-series data. It is engineered up from PostgreSQL and packaged as a PostgreSQL extension, providing automatic partitioning across time and space (partitioning key), as well as full SQL support."
    end

    def description
      "An open-source time-series SQL database optimized for fast ingest and complex queries"
    end

    def build_steps
      [
        "./bootstrap -DPG_CONFIG=$PG_CONFIG #{bootstrap_flags.map { |f| "-D#{f}" }.join(" ")}",
        "cmake --build build --parallel"
      ]
    end

    def install_steps
      [
        "DESTDIR=$PGPM_BUILDROOT cmake --build build --target install"
      ]
    end

    def build_dependencies
      super + %w[openssl-devel cmake]
    end

    def dependencies
      super + %w[openssl]
    end

    protected

    def bootstrap_flags
      []
    end
  end
end
