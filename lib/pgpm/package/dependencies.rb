# frozen_string_literal: true

require "tsort"

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

      def topologically_ordered_with_dependencies
        TopologicalPackageSorter.new([self, *all_requirements]).sorted_packages
      end

      class TopologicalPackageSorter
        include TSort

        def initialize(packages)
          @packages = packages.each_with_object({}) do |pkg, hash|
            hash[pkg.name] = pkg
          end
        end

        def tsort_each_node(&block)
          @packages.each_key(&block)
        end

        def tsort_each_child(node, &block)
          package = @packages[node]
          package.requires.each { |req| block.call(req) if @packages.key?(req) }
        end

        def sorted_packages
          tsort.map { |name| @packages[name] }.reverse
        end
      end

      def c_files_present?
        Dir.glob("*.c", base: source).any?
      end
    end
  end
end
