# frozen_string_literal: true

module Pgpm
  module Deb
    class Builder

      def initialize(spec)
        @spec = spec
        @image_name = "quay.io/qount25/pgpm-debian12"
        @container_name = "pgpm-debian12_build-#{Time.now.to_i}_#{rand(10000)}"
      end

      def build
        puts "build()"
        prepare
        generate_deb_src_files
        create_container
        run_pbuilder
        copy_build_from_container
        cleanup
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
          system("podman pull quay.io/qount25/pgpm-debian12")
        else
          puts "  Image #{@image_name} already exists! OK"
        end

        create_opts = " -v #{@pgpm_dir}:/root/pgpm"
        create_opts += ":z" if selinux_enabled?
        create_opts += " --privileged --annotation run.oci.keep_original_groups=1"
        create_opts += " --name #{@container_name} #{@image_name}"

        puts "  Creating and starting container #{@container_name}"
        puts "    podman run -dti #{create_opts}"
        system("podman run -dti #{create_opts}")
      end

      def generate_deb_src_files
        puts "Generating debian files..."
        Dir.mkdir "#{@pgpm_dir}/source/debian"
        [:changelog, :control, :copyright, :files, :rules].each do |f|
          puts "  -> #{@pgpm_dir}/source/debian/#{f}"
          File.write "#{@pgpm_dir}/source/debian/#{f}", @spec.generate(f)
        end
        File.chmod 0740, "#{@pgpm_dir}/source/debian/rules" # rules file must be executable
      end

      def run_pbuilder
        puts "Building a .deb package with pbuilder..."
        cmd_pref = "podman exec -w /root/pgpm/source #{@container_name} "
        system("#{cmd_pref} dpkg-buildpackage --build=source")
        exit(1) if $?.to_i > 0
        dsc_fn = "#{@spec.package.name}-#{@spec.package.version.to_s}_0-1.dsc"
        system("#{cmd_pref} fakeroot pbuilder build ../#{dsc_fn}")
        exit(1) if $?.to_i > 0
      end

      def copy_build_from_container
        puts "Moving .deb file from podman container into current directory..."
        cmd_pref = "podman exec #{@container_name} "
        arch = "amd64"
        deb_fn = "#{@spec.full_pkg_name}.deb"
        system("#{cmd_pref} mv /var/cache/pbuilder/result/#{deb_fn} /root/pgpm/out/")
        FileUtils.mv("#{@pgpm_dir}/out/#{deb_fn}", Dir.pwd)
      end

      def run_container_command(cmd)
      end

      def cleanup
        puts "Cleaning up..."

        # Stop and destroy podman container
        puts "  Stopping podman container: #{@container_name}"
        system("podman stop #{@container_name}")
        puts "  Destroying podman container: #{@container_name}"
        system("podman container rm #{@container_name}")

        # Remove temporary files
        #
        # Make sure @pgpm_dir starts with "/tmp/" or we may accidentally
        # delete something everything! You can never be sure!
        if @pgpm_dir.start_with?("/tmp/")
          puts "  Removing temporary files in #{@pgpm_dir}"
          FileUtils.rm_rf(@pgpm_dir)
        else
          puts "WARNING: will not remove temporary files, strange path: \"#{@pgpm_dir}\""
        end
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
