# frozen_string_literal: true

module Pgpm
  class Package
    module Packaging

      attr_accessor :os

      def to_rpm_spec(**opts)
        Pgpm::RPM::Spec.new(self, **opts)
      end

      def to_deb_spec(**opts)
        Pgpm::Deb::Spec.new(self, **opts)
      end

    end
  end
end
