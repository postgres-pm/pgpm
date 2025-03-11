# frozen_string_literal: true

module Pgpm
  class Package
    module Building
      def configure_steps
        []
      end

      def build_info
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          { rules: "" }
        when "rocky+epel-9", "redhat", "fedora"
          { build_steps: [], install_steps: [] }
        end
      end

      def source_url_directory_name
        nil
      end
    end
  end
end
