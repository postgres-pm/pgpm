# frozen_string_literal: true

module Pgpm
  class Package
    module Packaging

      def to_rpm_spec(**opts)
        Pgpm::RPM::Spec.new(self, **opts)
      end

      def to_deb_spec(**opts)
binding.break
        Pgpm::Deb::Spec.new(self, **opts)
      end

    end
  end
end
