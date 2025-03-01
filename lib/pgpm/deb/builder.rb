# frozen_string_literal: true

module Pgpm
  module Deb
    class Builder

      def initialize(spec)
        @spec = spec
      end

      def build
        puts "build()"
        p @spec
        #create_container
        #generate_deb_src_files
        #run_pbuilder
        #copy_build_from_container
        #destroy_container
      end

      private

      def create_container
        # pull pgpm-enabled debian podman image if doesn't exist locally
        # create a new container with that image
        # and @spec.package.source mounted into the container
      end

      def generate_deb_src_files
        @spec.generate_rules
        @spec.generate_control
        @spec.generate_licence
        @spec.generate_version
        # save generated content into actual files
      end

      def run_pbuilder
      end

      def copy_build_from_container
      end

      def copy_into_container(dest_dir_in_container)
      end

      def copy_from_container(dest_dir_on_host)
      end

      def destroy_container
      end

      def run_container_command(cmd)
      end

      def safe_package_name
        @spec.package.name.gsub(%r{/}, "__")
      end

    end
  end
end
