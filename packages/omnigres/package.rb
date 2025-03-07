# frozen_string_literal: true

require "minitar"
require "find"
require "zlib"
require "progress"
require "oj"
require "digest"

# rubocop:disable Metrics/ModuleLength
module Omnigres
  module Package
    module ClassMethods
      def package_versions
        ExtensionDiscovery.new.extension_versions[package_name(exclude_namespace: true)]
      end
    end

    def self.included(base_class)
      base_class.extend(ClassMethods)
      base_class.class_eval do
        github "omnigres/omnigres", download_version_tags: false
      end
    end

    def description
      summary
    end

    def version_git_commit
      discovery = ExtensionDiscovery.new
      intended_commit = discovery.extension_git_revisions[name][version]
      dir = discovery.git.dir.to_s
      most_likely_extension_dir = File.join(dir, extension_path(dir))
      # If there has been no changes between the intended commit and the source code of the extension,
      # we can just use HEAD and get a newer build system.
      # However, there are some corner cases: because we allowed for some extensions to share tenancy
      # in the same directory (looking at you, omni_vfs_types_v1), they are not recognized here correctly
      # that there has been no change and that renders current omni_vfs_types_v1 (Oct 24, 2024) unbuildable,
      # which is an unintentional outcome.
      # To fix that, we check if migrate/#{name} is present:
      migrate_directory = File.join(dir, extension_path(dir), "migrate", name)
      # and if it is, we use that particular directory as a marker
      check_path = File.directory?(migrate_directory) ? migrate_directory : most_likely_extension_dir
      # It is not absolutely robust, but if we only use this technique for private in-tree extensions going
      # forward, this should be sufficient

      # Now, we try to see what has actually changed
      log = discovery.git.log.object(check_path).between(intended_commit, "origin/master")
      changed_files = []
      log.each do |commit|
        next if commit.parents.empty? # Skip commits with no parents (e.g., initial commit)

        diff = commit.diff(commit.parents.first)

        changed_files += diff.stats[:files].keys.select { |f| f.start_with?(extension_path(dir)) }.uniq
      end
      # Changelog modifications are not changing anything
      changed_files.reject! { |f| f =~ /CHANGELOG.md/ }

      if changed_files.empty?
        discovery.git.object("origin/master").log.first.sha
      else
        intended_commit
      end
    end

    def configure_steps
      extra_config = contains_vendorized_deps? ? "" : "-DCPM_SOURCE_CACHE=$(pwd)/deps/_deps "
      ["export PIP_CONFIG_FILE=$(pwd)/deps/pip.conf",
       "cmake -S #{extension_path} -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo " \
         "-DOPENSSL_CONFIGURED=1 -DPG_CONFIG=$PG_CONFIG #{extra_config} -DCMAKE_POSITION_INDEPENDENT_CODE=ON"]
    end

    def build_steps
      steps = [
        "cmake --build build --parallel --target inja",
        "cmake --build build --parallel --target package_extensions"
      ]
      if previous_version && !previous_version.broken? && !@no_migration
        steps.push("scripts/generate_upgrade.sh #{name} #{previous_version.version} " \
                     "$(pwd)/omnigres-#{previous_version.version_git_commit} #{version} $(pwd) #{depends_on_omni? || name == "omni" ? "yes" : "no"}")
      end
      steps
    end

    def install_steps
      steps = [
        "mkdir -p $PGPM_BUILDROOT/$($PG_CONFIG --sharedir)/extension",
        "mkdir -p $PGPM_BUILDROOT/$($PG_CONFIG --pkglibdir)",
        # Package .so artifacts
        "find build/packaged -name '#{name}*.so' -type f -exec cp {} $PGPM_BUILDROOT/$($PG_CONFIG --pkglibdir) \\;",
        # Package version-specific control file
        "cp build/packaged/extension/#{name}--#{version}.control $PGPM_BUILDROOT/$($PG_CONFIG --sharedir)/extension",
        # Package version-specific init file
        "cp build/packaged/extension/#{name}--#{version}.sql $PGPM_BUILDROOT/$($PG_CONFIG --sharedir)/extension"
      ]
      if previous_version && !previous_version.broken? && !@no_migration
        steps.push("cp build/packaged/extension/#{name}--#{previous_version.version}--#{version}.sql $PGPM_BUILDROOT/$($PG_CONFIG --sharedir)/extension")
      end
      steps
    end

    def license
      "Apache 2.0"
    end

    def build_dependencies
      %w[cmake openssl-devel python3 python3-devel nc sudo git] + super
    end

    def dependencies
      ["openssl"] + super
    end

    def native?
      super(extension_path)
    end

    def broken?
      # omni < 0.1.5 does not work on pg17+ and the package is known to depend on `omni` (or is `omni` itself)
      ((depends_on_omni? || name == "omni") && artifacts.keys.any? { |(k, v)| k == "omni" && Pgpm::Package::Version.new(v) < "0.1.5" } &&
        Pgpm::Postgres::Distribution.in_scope.major_version >= 17) ||
        ## Versions with cmake/dependencies are not supported
        !File.directory?(File.join(source, "cmake", "dependencies"))
    end

    def depends_on_omni?
      false
    end

    def source_url_directory_name
      "omnigres-#{version_git_commit}"
    end

    class UnsupportedVersion < StandardError
      def message
        "This version of omnigres extension is too old"
      end
    end

    def deps_tar_gz(dir_name = "deps")
      recipe_hash = Digest::SHA1.hexdigest(File.read(__FILE__) + scripts_tar_gz.read)
      src = source.to_s
      deps = File.join(src, dir_name)
      targz = File.join(src, "deps-#{recipe_hash}.tar.gz")
      unless File.exist?(targz)
        cmake_dependencies(dir_name)
        begin
          sgz = Zlib::GzipWriter.new(File.open(targz, "wb"))
          tar = Minitar::Output.open(sgz)
          files = Find.find(deps).filter do |entry|
            # Don't include .git
            Pathname(entry).each_filename.map { |f| f == ".git" }.none?
          end
          files.with_progress("Preparing #{dir_name}.tar.gz") do |entry|
            stat = File.stat(entry)
            data = File.directory?(entry) ? nil : File.binread(entry)
            info = { name: Pathname(entry).relative_path_from(src).to_s,
                     mode: stat.mode, uid: stat.uid, gid: stat.gid, mtime: stat.mtime }
            Minitar.pack_as_file(info, data, tar)
          end
        ensure
          tar.close
        end
      end
      Pgpm::OnDemandFile.new("#{dir_name}.tar.gz", -> { File.open(targz) })
    end

    def artifacts(src = nil)
      install_prerequisites
      recipe_hash = Digest::SHA1.hexdigest(File.read(__FILE__))
      src ||= source.to_s
      ready_marker = File.join(src, ".configure.#{recipe_hash}")
      unless File.exist?(ready_marker)
        pgpath = File.join(Pgpm::Cache.directory, ".omnigres.pg", Pgpm::Postgres::Distribution.in_scope.version)
        # Sadly, there was a bug in the cmake file before 0081991, substituting for incorrect PGSHAREDIR
        # Work around it with setting `PGSHAREDIR` preventatively
        share_fix = ""
        begin
          Git.open(src).object("0081991")
        rescue Git::GitExecuteError
          share_fix = "-e PGSHAREDIR=#{pgpath}/build/share"
        end
        unless Pgpm::Podman.run "run -ti #{share_fix} -v #{src}:#{src} -v #{Pgpm::Cache.directory}:#{Pgpm::Cache.directory} #{PGPM_BUILD_CONTAINER_IMAGE}  cmake -S #{src} -B #{src}/build -DOPENSSL_CONFIGURED=1 -DPGVER=#{Pgpm::Postgres::Distribution.in_scope.version} -DPGDIR=#{pgpath}"
          raise "Can't configure the project"
        end

        FileUtils.touch(ready_marker)
      end

      artifacts = File.read(File.join(src, "build", "artifacts.txt"))
      artifacts.each_line.map do |line|
        pkg, deps = line.split("#")
        deps = deps ? deps.chomp.split(",") : []
        deps = deps.map do |dep|
          dep_name, dep_ver = dep.split("=")
          [dep_name, dep_ver]
        end.to_h
        [pkg.chomp.split("="), deps]
      end.to_h
    end

    def requires
      artifacts[[name, version]].map do |(dep_name, dep_ver)|
        dep_name = "omnigres/#{dep_name}" if dep_name =~ /^omni_/ || dep_name == "omni"
        Pgpm::Package[dep_name][dep_ver]
      end
    end

    def original_sources
      method(:sources).super_method.call
    end

    def sources
      return @srcs if @srcs

      @srcs = original_sources
      unless contains_vendorized_deps?
        @srcs.push(deps_tar_gz)
      end
      if previous_version && !previous_version.broken?
        begin
          puts "Fetching previous version #{previous_version.version} to be able to generate migrations"
          @srcs.push(*previous_version.original_sources) # archive
          @srcs.push(previous_version.deps_tar_gz("deps-prev")) unless previous_version.contains_vendorized_deps?
        rescue UnsupportedVersion
          # ignore this one, just don't build an upgrade
          puts "Ignore #{previous_version.version}, it is unsupported"
          @srcs.pop # get the version out
          @no_migration = true
        end
      end

      @srcs.push(scripts_tar_gz)
      @srcs
    end

    def contains_vendorized_deps?
      # In 65c4d8e636197fd45c55aa02e4a4d5e26fffc453, we introduced a new deps system
      !File.exist?(File.join(source, "cmake", "dependencies", "CMakeLists.txt")) &&
        File.exist?(File.join(source, "cmake", "dependencies", "versions.cmake"))
    end

    private

    def extension_path(src = nil)
      src ||= source.to_s
      artifacts(src)
      File.read(File.join(src, "build", "paths.txt")).each_line.map do |line|
        ext, path = line.split(" ")
        return path if ext == name
      end
    end

    def previous_version
      return @previous_version if @previous_version

      sorted_versions = self.class.package_versions.sort
      index = sorted_versions.index(version)
      return nil if index.nil?
      return unless index.positive?

      @previous_version = self.class[sorted_versions[index - 1]]
    end

    def scripts_tar_gz
      s = String.new
      begin
        dir = File.join(File.dirname(__FILE__), "scripts")
        sgz = Zlib::GzipWriter.new(StringIO.new(s))
        tar = Minitar::Output.open(sgz)
        Find.find(dir) do |entry|
          stat = File.stat(entry)
          data = File.directory?(entry) ? nil : File.binread(entry)
          info = { name: Pathname(entry).relative_path_from(File.dirname(__FILE__)).to_s,
                   mode: stat.mode, uid: stat.uid, gid: stat.gid, mtime: stat.mtime }
          Minitar.pack_as_file(info, data, tar)
        end
      ensure
        # Closes both tar and sgz.
        tar.close
      end
      Pgpm::OnDemandFile.new("scripts.tar.gz", -> { StringIO.open(s) })
    end

    PGPM_BUILD_CONTAINER = "fedora:41 dnf -y install git gcc zlib-devel libxml2-devel libxslt-devel cmake gcc g++ python3-devel openssl-devel bison flex readline-devel nc perl-FindBin perl-File-Compare"
    PGPM_BUILD_CONTAINER_IMAGE = "pgpm-#{Digest::SHA256.hexdigest(PGPM_BUILD_CONTAINER)}".freeze

    def install_prerequisites
      return if @prerequisites_installed

      @os = Pgpm::OS.auto_detect
      if @os.is_a?(Pgpm::OS::RedHat)
        images = Oj.load(Pgpm::Podman.run("images --format json", print_stdout: false))
        unless images.flat_map { |i| i["Names"] }.include?("localhost/#{PGPM_BUILD_CONTAINER_IMAGE}:latest")
          tmpfile = Tempfile.new
          Pgpm::Podman.run "run -ti --cidfile #{tmpfile.path} #{PGPM_BUILD_CONTAINER}"
          id = File.read(tmpfile.path)
          tmpfile.unlink
          Pgpm::Podman.run "commit #{id} #{PGPM_BUILD_CONTAINER_IMAGE}"
        end
      end
      @prerequisites_installed = true
    end

    def cmake_dependencies(dir_name = "deps")
      install_prerequisites

      recipe_hash = Digest::SHA1.hexdigest(File.read(__FILE__))
      deps = File.join(source, dir_name)
      src = source.to_s
      ready_marker = File.join(src, ".deps.#{recipe_hash}")
      return if File.exist?(ready_marker)
      raise UnsupportedVersion unless File.directory?(File.join(src, "cmake", "dependencies"))

      unless Pgpm::Podman.run "run -ti -v #{Pgpm::Cache.directory}:#{Pgpm::Cache.directory} #{PGPM_BUILD_CONTAINER_IMAGE} cmake -S #{src}/cmake/dependencies -B #{deps} -DCPM_SOURCE_CACHE=#{deps}/_deps"
        raise "Can't fetch dependencies"
      end

      FileUtils.touch(ready_marker)
    end
  end
end
# rubocop:enable Metrics/ModuleLength
