# frozen_string_literal: true

require "English"
require "debug"

module Pgpm
  module Deb
    class Builder
      def initialize(spec)
        @spec = spec
        @container_name = "pgpm-debian_build-#{Time.now.to_i}_#{rand(10_000)}"
        @pgpm_dir = Dir.mktmpdir
      end

      def build
        pull_image
        start_container
        patch_pbuilder

        prepare_versioned_source
        generate_deb_src_files(:versioned)
        run_build(:versioned)
        copy_build_from_container(:versioned)

        prepare_default_source
        generate_deb_src_files(:default)
        run_build(:default)
        copy_build_from_container(:default)

        cleanup
      end

      private

      # Depends on postgres version and arch
      def image_name
        "quay.io/qount25/pgpm-debian-pg#{@spec.package.postgres_major_version}-#{@spec.arch}"
      end

      def prepare_versioned_source
        puts "Preparing build..."
        puts "  Creating container dir structure..."
        Dir.mkdir "#{@pgpm_dir}/source-versioned"
        Dir.mkdir "#{@pgpm_dir}/out"

        puts "  Downloading and unpacking sources to #{@pgpm_dir}"

        fn = nil
        @spec.sources.map do |src|
          srcfile = File.join(@pgpm_dir.to_s, src.name)
          File.write(srcfile, src.read)
          fn = src.name
        end

        system("tar -xf #{@pgpm_dir}/#{fn} -C #{@pgpm_dir}/source-versioned/")
        FileUtils.remove("#{@pgpm_dir}/#{fn}")

        untar_dir_entries = Dir.entries("#{@pgpm_dir}/source-versioned/").reject do |entry|
          [".", ".."].include?(entry)
        end

        if untar_dir_entries.size == 1
          entry = untar_dir_entries[0]
          if File.directory?("#{@pgpm_dir}/source-versioned/#{entry}")
            FileUtils.mv "#{@pgpm_dir}/source-versioned/#{entry}", "#{@pgpm_dir}/"
            FileUtils.remove_dir "#{@pgpm_dir}/source-versioned/"
            FileUtils.mv "#{@pgpm_dir}/#{entry}", "#{@pgpm_dir}/source-versioned"
          end
        end

        ["prepare_artifacts.sh"].each do |f|
          script_fn = File.expand_path("#{__dir__}/scripts/#{f}")
          FileUtils.cp script_fn, "#{@pgpm_dir}/source-versioned/"
        end
      end

      def prepare_default_source
        Dir.mkdir "#{@pgpm_dir}/source-default"

        # 1. All pbuilder builds are in /var/cache/pbuilder/build. At this point
        # there's only one build, but we don't know what the directory is named
        # (the name is usually some numbers). So we just pick the first (and only)
        # entry at this location and this is our build dir.
        pbuilds_dir = "/var/cache/pbuilder/build"
        cmd = "ls -U #{pbuilds_dir} | head -1"
        build_dir = `podman exec #{@container_name} /bin/bash -c '#{cmd}'`.strip
        puts "BUILD DIR IS: #{pbuilds_dir}/#{build_dir}"

        # 2. Determine the name of the .control file inside the versioned build
        deb_dir = "#{pbuilds_dir}/#{build_dir}/build/#{@spec.deb_pkg_name(:versioned)}-0/debian/#{@spec.deb_pkg_name(:versioned)}"
        control_fn = "#{deb_dir}/usr/share/postgresql/#{@spec.package.postgres_major_version}/extension/#{@spec.package.extension_name}--#{@spec.package.version}.control"

        # 3. Copy .control file to the source-default dir
        puts "Copying #{control_fn} into /root/pgpm/source-default/"
        target_control_fn = "/root/pgpm/source-default/#{@spec.package.extension_name}.control"
        cmd = "cp #{control_fn} #{target_control_fn}"
        system("podman exec #{@container_name} /bin/bash -c '#{cmd}'")

        ["install_default_control.sh"].each do |fn|
          script_fn = File.expand_path("#{__dir__}/scripts/#{fn}")
          FileUtils.cp script_fn, "#{@pgpm_dir}/source-default/"
        end
      end

      def pull_image
        puts "Checking if podman image exists..."
        # Check if image exists
        system("podman image exists #{image_name}")
        if $CHILD_STATUS.to_i.positive? # image doesn't exist -- pull image from a remote repository
          puts "  No. Pulling image #{image_name}..."
          system("podman pull #{image_name}")
        else
          puts "  Yes, image #{image_name} already exists! OK"
        end
      end

      def generate_deb_src_files(pkg_type = :versioned)
        puts "Generating debian files..."
        Dir.mkdir "#{@pgpm_dir}/source-#{pkg_type}/debian"
        %i[changelog control copyright files rules].each do |f|
          puts "  -> #{@pgpm_dir}/source-#{pkg_type}/debian/#{f}"
          File.write "#{@pgpm_dir}/source-#{pkg_type}/debian/#{f}", @spec.generate(f, pkg_type)
        end
        File.chmod 0o740, "#{@pgpm_dir}/source-#{pkg_type}/debian/rules" # rules file must be executable
      end

      def start_container
        # podman create options
        create_opts = " -v #{@pgpm_dir}:/root/pgpm"
        create_opts += ":z" if selinux_enabled?
        create_opts += " --privileged --tmpfs /tmp"
        create_opts += " --name #{@container_name} #{image_name}"

        puts "  Creating and starting container #{@container_name} & running pbuilder"
        system("podman create -it #{create_opts}")
        exit(1) if $CHILD_STATUS.to_i.positive?
        system("podman start #{@container_name}")
        exit(1) if $CHILD_STATUS.to_i.positive?
      end

      # Prevents clean-up after pbuilder finishes. There's no option
      # in pbuilder to do it, so we have to patch it manually. The issue is
      # with pbuilder not being able to delete some directories (presumably,
      # due to directory names starting with ".") and returning error.
      #
      # This little patch avoids the error by returning from the python cleanup
      # function early -- because the package itself is built successfully and
      # we don't actually care that pbuilder is unable to clean something up.
      # The container is going to be removed anyway, so it's even less work as
      # a result.
      def patch_pbuilder
        cmd = "sed -E -i \"s/(^function clean_subdirectories.*$)/\\1\\n  return/g\" /usr/lib/pbuilder/pbuilder-modules"
        system("podman exec #{@container_name} /bin/bash -c '#{cmd}'")
      end

      def run_build(pkg_type = :versioned)
        dsc_fn = "#{@spec.deb_pkg_name(pkg_type)}_0-1.dsc"
        deb_fn = "#{@spec.deb_pkg_name(pkg_type)}_0-1_#{@spec.arch}.deb"

        cmds = []
        cmds << "dpkg-buildpackage --build=source -d" # -d flag helps with dependencies error
        cmds << "fakeroot pbuilder build ../#{dsc_fn}"
        cmds << "mv /var/cache/pbuilder/result/#{deb_fn} /root/pgpm/out/"

        puts "  Building package with pbuilder..."
        cmds.each do |cmd|
          system("podman exec -w /root/pgpm/source-#{pkg_type} #{@container_name} /bin/bash -c '#{cmd}'")
          exit(1) if $CHILD_STATUS.to_i.positive?
        end
      end

      def copy_build_from_container(pkg_type = :versioned)
        puts "Copying .deb file from podman container into current directory..."
        deb_fn = "#{@spec.deb_pkg_name(pkg_type)}_0-1_#{@spec.arch}.deb"
        deb_copy_fn = "#{@spec.deb_pkg_name(pkg_type)}_#{@spec.arch}.deb"
        FileUtils.cp("#{@pgpm_dir}/out/#{deb_fn}", "#{Dir.pwd}/#{deb_copy_fn}")
      end

      def cleanup
        puts "Cleaning up..."

        puts "  Stopping destroying podman container: #{@container_name}"
        system("podman container stop #{@container_name}")
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
    end
  end
end
