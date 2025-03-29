# frozen_string_literal: true

require "rbconfig"

module Pgpm
  module OS
    class Debian < Pgpm::OS::Linux
      def self.auto_detect
        # TODO: distinguish between flavors of Debian
        Debian12.new
      end

      def self.name
        "debian"
      end

      def mock_config; end
    end

    class Debian12 < Pgpm::OS::Debian
      def self.name
        "debian-12"
      end

      def self.builder
        Pgpm::Debian::Builder
      end

      def mock_config
        "debian-12-#{Pgpm::Arch.in_scope.name}+pgdg"
      end
    end
  end
end
