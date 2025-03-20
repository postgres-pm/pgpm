# frozen_string_literal: true

module Pgpm
  class Package
    module Building
      def configure_steps
        []
      end

      def source_url_directory_name
        nil
      end
    end
  end
end
