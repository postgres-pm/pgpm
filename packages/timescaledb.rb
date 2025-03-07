# frozen_string_literal: true

class Timescaledb < Pgpm::Package
  github "timescale/timescaledb"

  def description
    "An open-source time-series SQL database optimized for fast ingest and " +
    "complex queries"
  end

  def summary
      "TimescaleDB is an open-source database designed to make SQL "        +
      "scalable for time-series data. It is engineered up from PostgreSQL " +
      "and packaged as a PostgreSQL extension, providing automatic "        +
      "partitioning across time and space (partitioning key), as well as "  +
      "full SQL support."
  end

  def build_info_for(os)
    case os.downcase
    when "debian", "ubuntu"
      {
        dependencies: [],
        build_dependencies: ["openssl-dev", "cmake"],
        rules:  "override_dh_auto_configure:\n" +
                "  dh_auto_configure -- -DCMAKE_BUILD_TYPE=\"Release\""
      }
    when "rocky", "redhat", "fedora"
      {
        dependencies: [],
        build_dependencies: ["openssl-devel", "cmake"],
        build_steps: [
          "./bootstrap -DPG_CONFIG=$PG_CONFIG #{bootstrap_flags.map { |f| "-D#{f}" }.join(" ")}",
          "cmake --build build --parallel"
        ],
        install_steps: [
          "DESTDIR=$PGPM_BUILDROOT cmake --build build --target install"
        ]
      }
    end
  end

  protected

  def bootstrap_flags
    []
  end

end
