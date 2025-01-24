# frozen_string_literal: true

class Citus < Pgpm::Package
  github "citusdata/citus"

  def build_steps
    ["./configure"] + super
  end

  def build_dependencies
    super + %w[libcurl-devel lz4-devel libzstd-devel openssl-devel krb5-devel]
  end

  def dependencies
    super + %w[libcurl lz4 libzstd openssl krb5-libs]
  end

  def broken?
    # https://github.com/citusdata/citus/issues/7708
    version < 13 && Pgpm::Postgres::Distribution.in_scope.major_version > 16
  end
end
