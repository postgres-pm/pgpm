# frozen_string_literal: true

class Pgsodium < Pgpm::Package
  github "michelp/pgsodium"

  def build_dependencies
    deps = case Pgpm::OS.in_scope.class.name
           when "debian", "ubuntu"
             ["libsodium-dev (>= 1.0.18)"]
           when "rocky+epel-9", "redhat", "fedora"
             ["libsodium-devel >= 1.0.18"]
           end
    super + deps
  end

  def dependencies
    deps = case Pgpm::OS.in_scope.class.name
           when "debian", "ubuntu"
             ["libsodium (>= 1.0.18)"]
           when "rocky+epel-9", "redhat", "fedora"
             ["libsodium >= 1.0.18"]
           end
    super + deps
  end

  def broken?
    version >= "3.0.0" && Pgpm::Postgres::Distribution.in_scope.major_version < 14
  end
end
