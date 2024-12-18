# frozen_string_literal: true

class PgIncremental < Pgpm::Package
  github "crunchydata/pg_incremental"

  def requires
    super + [Pgpm::Package["pg_cron"][:latest]]
  end
end
