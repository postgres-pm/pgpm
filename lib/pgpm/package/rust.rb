# frozen_string_literal: true

require "open-uri"
require "perfect_toml"

module Pgpm
  class Package
    # rubocop:disable Metrics/ModuleLength
    module Rust
      ARCH_MAPPING = { "arm64" => "aarch64" }.freeze
      OS_MAPPING = { "linux" => "unknown-linux-gnu" }.freeze

      def rust_default_features
        []
      end

      def sources
        if cargo_toml_present?
          return @srcs if @srcs

          @srcs = super

          vendor_dir = Dir.mktmpdir("pgpm")

          podman_cmd = "run -v #{Pgpm::Cache.directory}:#{Pgpm::Cache.directory} -v #{vendor_dir}:#{vendor_dir} -i rust"
          Podman.run("#{podman_cmd} cargo add --manifest-path #{source}/Cargo.toml --dev cargo-pgrx@#{pgrx_version}")
          Podman.run("#{podman_cmd} cargo vendor --versioned-dirs --manifest-path #{source}/Cargo.toml #{vendor_dir}/vendor")
          vendored_pgrx_version = Dir.glob("cargo-pgrx-*", base: File.join(vendor_dir, "vendor"))[0].split("-").last
          # Get cargo-pgrx's dependencies vendored, too
          Podman.run("#{podman_cmd} cargo vendor --no-delete --versioned-dirs --manifest-path #{vendor_dir}/vendor/cargo-pgrx-#{vendored_pgrx_version}/Cargo.toml #{vendor_dir}/vendor")
          File.write(File.join(vendor_dir, "vendor", "PGRX_VERSION"), vendored_pgrx_version) # Write it down so that configure steps don't have to guess

          @srcs.push(vendored_tar_gz(vendor_dir))

          FileUtils.rm_rf(vendor_dir)

          @srcs.push(Pgpm::OnDemandFile.new("rust.tar.xz", lambda {
            # rubocop:disable Security/Open
            URI.open(channel_rust_stable[:pkg][:rust][:target][rust_target.to_sym][:xz_url])
            # rubocop:enable Security/Open
          }))

          @srcs
        else
          super
        end
      end

      def build_dependencies
        if cargo_toml_present?
          super + [
            # I currently have no hope of being able to get distros to support bleeding-edge MSRV,
            # so this is what we mean but for now we just package Rust with us (which makes our sources
            # large, sadly)
            # "cargo >= #{rust_minimum_version}", "rust >= #{rust_minimum_version}",
            #     "rustfmt >= #{rust_minimum_version}", # pgrx->bindgen
            "openssl-devel" # pgrx needs it
          ]
        else
          super
        end
      end

      def configure_steps
        if cargo_toml_present?
          config = <<~EOF
            [profile.release-with-debug]
            inherits = "release"
            debug = true

            [source.crates-io]
            replace-with = "vendored-sources"

            [source.vendored-sources]
            directory = "vendor"
          EOF
          super + [
            "rust-#{current_stable_rust}-#{rust_target}/install.sh --prefix=rust",
            "export PATH=$(pwd)/rust/bin:$PATH",
            "mkdir -p .cargo && echo '#{config}' >> .cargo/config.toml", "cargo install --path vendor/cargo-pgrx-$(cat vendor/PGRX_VERSION)", "cargo pgrx init --pg#{Pgpm::Postgres::Distribution.in_scope.major_version} $PG_CONFIG", "cargo generate-lockfile --offline"
          ]
        else
          super
        end
      end

      def build_steps
        features = ["pg#{Pgpm::Postgres::Distribution.in_scope.major_version}"] + rust_default_features
        if cargo_toml_present?
          super + [
            "export PATH=$(pwd)/rust/bin:$PATH",
            "cargo build --profile release-with-debug --no-default-features --features #{features.join(",")}"
          ]
        else
          super
        end
      end

      def install_steps
        if cargo_toml_present?
          super + [
            "export PATH=$(pwd)/rust/bin:$PATH",
            "PGPM_REDIRECT_TO_BUILDROOT=1 cargo pgrx install --profile release-with-debug --pg-config $(pwd)/pg_config.sh"
          ]
        else
          super
        end
      end

      private

      def rust_target
        arch = Pgpm::Arch.in_scope.name
        os = Pgpm::OS.in_scope.kind
        "#{ARCH_MAPPING[arch] || arch}-#{OS_MAPPING[os] || os}"
      end

      def cargo_toml_present?
        File.exist?(File.join(source, "Cargo.toml"))
      end

      def cargo_toml
        @cargo_toml ||= PerfectTOML.load_file(File.join(source, "Cargo.toml"), symbolize_names: true)
      end

      def pgrx_version
        cargo_toml[:dependencies][:pgrx]
      end

      def rust_minimum_version
        # pgrx has no MSRV policy, always requiring the latest
        current_stable_rust
      end

      def channel_rust_stable
        @@channel_rust_stable ||= PerfectTOML.load_file(URI.open("https://static.rust-lang.org/dist/channel-rust-stable.toml"), symbolize_names: true)
      end

      def current_stable_rust
        channel_rust_stable[:pkg][:rust][:version].split(" ").first
      end

      def vendored_tar_gz(dir)
        s = String.new
        begin
          sgz = Zlib::GzipWriter.new(StringIO.new(s))
          tar = Minitar::Output.open(sgz)
          Find.find(dir) do |entry|
            stat = File.stat(entry)
            data = File.directory?(entry) ? nil : File.binread(entry)
            info = { name: Pathname(entry).relative_path_from(dir).to_s,
                     mode: stat.mode, uid: stat.uid, gid: stat.gid, mtime: stat.mtime }
            Minitar.pack_as_file(info, data, tar)
          end
        ensure
          # Closes both tar and sgz.
          tar.close
        end
        Pgpm::OnDemandFile.new("vendored-sources.tar.gz", -> { StringIO.open(s) })
      end

      # rubocop:enable Metrics/ModuleLength
    end
  end
end
