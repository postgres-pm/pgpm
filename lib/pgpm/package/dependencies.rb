# frozen_string_literal: true

module Pgpm
  class Package
    module Dependencies
      def build_dependencies
        return ["gcc"] if c_files_present?

        []
      end

      def dependencies
        []
      end

      def requires
        []
      end

      def all_requirements
        requires.flat_map { |r| [r, *r.all_requirements] }.uniq
      end

      def c_files_present?
        Dir.glob("*.c", base: source).any?
      end
    end
  end
end
