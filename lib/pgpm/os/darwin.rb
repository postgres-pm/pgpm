# frozen_string_literal: true

module Pgpm
  module OS
    class Darwin < Pgpm::OS::Unix
      def self.name
        "darwin"
      end

      def self.auto_detect
        new
      end
    end
  end
end
