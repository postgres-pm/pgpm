# frozen_string_literal: true

require "tsort"
require "debug"

module Pgpm
  class Package
    module Dependencies

      attr_accessor :postgres_major_version

      def build_dependencies
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          deps = [
            "postgresql-#{postgres_major_version}",
            "postgresql-server-dev-#{postgres_major_version}",
            "postgresql-common"
          ]
          if self.native?
            deps << "build-essential"
          end
        when "rocky+epel-9", "redhat", "fedora"
          [
            "postgresql-#{postgres_major_version}",
            "postgresql-server-devel-#{postgres_major_version}",
            "postgresql-common"
          ]
        end
      end

      def dependencies
        case Pgpm::OS.in_scope.class.name
        when "debian", "ubuntu"
          [ "postgresql-#{postgres_major_version}" ]
        when "rocky+epel-9", "redhat", "fedora"
          [ "postgresql-#{postgres_major_version}" ]
        end
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
