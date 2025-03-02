# frozen_string_literal: true

module Pgpm
  module Deb
    class Builder

      def initialize(spec)
        @spec = spec
        @image_name = "pgpm-debian12"
        @container_name = "pgpm-debian12_build-#{Time.now.to_i}_#{rand(10000)}"
      end

      def build
        puts "build()"
        prepare
        generate_deb_src_files
        #create_container
        #run_pbuilder
        #copy_build_from_container
        #cleanup
      end

      private

      def prepare
        puts "Preparing build..."
        puts "  Creating container dir structure..."
        @pgpm_dir  = Dir.mktmpdir
        Dir.mkdir "#{@pgpm_dir}/source"
        Dir.mkdir "#{@pgpm_dir}/out"
        puts "  Copying #{@spec.package.source.to_s} to #{@pgpm_dir}/source/"
        FileUtils.copy_entry @spec.package.source.to_s, "#{@pgpm_dir}/source/"
      end

      def create_container
        puts "Creating a podman container..."
        # Check if image exists
        system("podman image exists #{@image_name}")
        if $?.to_i > 0 # image doesn't exist -- pull image from a remote repository
          puts "  Pulling image #{@image_name}..."
          # TODO
        else
          puts "  Image #{@image_name} already exists! OK"
        end

        create_opts = " -v #{@pgpm_dir}:/root/pgpm"
        create_opts += ":z" if selinux_enabled?
        create_opts += " --privileged"
        create_opts += " --name #{@container_name} #{@image_name}"

        puts "  Creating and starting container #{@container_name}"
        puts "    podman run -dti #{create_opts}"
        system("podman run -dti #{create_opts}")
      end

      def generate_deb_src_files
        puts "Generating debian files..."
        Dir.mkdir "#{@pgpm_dir}/debian"
        [:changelog, :control, :copyright, :files, :rules].each do |f|
          puts "  -> #{@pgpm_dir}/debian/#{f}"
          File.write "#{@pgpm_dir}/debian/#{f}", @spec.generate(f)
        end
        File.chmod 0740, "#{@pgpm_dir}/debian/rules" # rules file must be executable
      end

      def run_pbuilder
      end

      def copy_build_from_container
      end

      def run_container_command(cmd)
      end

      def cleanup
      end

      # Needed because SELinux requires :z suffix for mounted directories to
      # be accessible -- otherwise we get "Permission denied" when cd into a
      # mounted dir inside the container.
      def selinux_enabled?
        # This returns true or false by itself
        system("sestatus | grep 'SELinux status' | grep -o 'enabled'")
      end

      def safe_package_name
        @spec.package.name.gsub(%r{/}, "__")
      end

    end
  end
end
