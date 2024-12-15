# frozen_string_literal: true

class Pgmp < Pgpm::Package
  github "dvarrazzo/pgmp", tag_prefix: "rel-"

  def build_dependencies
    super + %w(gmp-devel)
  end

  def dependencies
    super + %w(gmp)
  end
end
