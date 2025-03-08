# frozen_string_literal: true

module Pgpm
  class Package
    module Building
      def configure_steps
        []
      end

      def build_info
        case @os
        when "debian", "ubuntu"
          { rules: "" }
        when "rocky", "redhat", "fedora"
          { build_steps: [], install_steps: [] }
        end
      end

      def source_url_directory_name
        nil
      end
    end
  end
end
