# frozen_string_literal: true

module Pgpm
  module RPM
    module Mock
      class Operation
        def self.buildsrpm(spec, sources, config: nil, result_dir: nil, cb: nil)
          buffer_result_dir = Dir.mktmpdir("pgpm")
          args = [
            "--buildsrpm", "--spec", spec, "--resultdir",
            buffer_result_dir
          ]
          args.push("--sources", sources) if sources
          args.push("-r", config.to_s) unless config.nil?
          paths = [buffer_result_dir]
          paths.push(File.dirname(spec))
          paths.push(File.dirname(sources)) if sources
          new(*args, paths:, cb: lambda {
            rpms = Dir.glob("*.rpm", base: buffer_result_dir).map do |f|
              FileUtils.cp(Pathname(buffer_result_dir).join(f), result_dir) unless result_dir.nil?
              File.join(File.absolute_path(result_dir), f)
            end
            FileUtils.rm_rf(buffer_result_dir)
            cb.call unless cb.nil?
            rpms
          })
        end

        def self.rebuild(srpm, config: nil, result_dir: nil, cb: nil)
          buffer_result_dir = Dir.mktmpdir("pgpm")
          args = [
            "--rebuild", "--chain", "--recurse", srpm, "--localrepo", buffer_result_dir
          ]
          args.push("-r", config.to_s) unless config.nil?
          paths = [buffer_result_dir]
          paths.push(File.dirname(srpm))
          new(*args, paths:, cb: lambda {
            # Here we glob for **/*.rpm as ``--localrepo` behaves differently from
            # `--resultdir`
            rpms = Dir.glob("**/*.rpm", base: buffer_result_dir).map do |f|
              FileUtils.cp(Pathname(buffer_result_dir).join(f), result_dir) unless result_dir.nil?
              File.join(File.absolute_path(result_dir), f)
            end
            FileUtils.rm_rf(buffer_result_dir)
            cb.call unless cb.nil?
            rpms
          })
        end

        def initialize(*args, opts: nil, paths: [], cb: nil)
          @args = args
          @cb = cb
          @paths = paths
          @opts = opts || { "print_main_output" => "True", "pgdg_version" => Postgres::Distribution.in_scope.major_version }
        end

        attr_reader :args, :cb

        def call
          options = @opts.flat_map { |(k, v)| ["--config-opts", "#{k}=#{v}"] }.compact.join(" ")
          command = "mock #{options} #{@args.join(" ")}"
          map_paths = @paths.map { |p| "-v #{p}:#{p}" }.join(" ")
          raise "Failed to execute `#{command}`" unless Podman.run("run -v #{Dir.pwd}:#{Dir.pwd} #{map_paths} --privileged -i ghcr.io/postgres-pm/pgpm #{command}")

          @cb&.call
        end

        def chain(op)
          raise ArgumentError, "can't chain non-rebuild operations" unless op.args.include?("--rebuild") && @args.include?("--rebuild")

          args.insert(args.index("--localrepo"), *op.args[op.args.index("--recurse") + 1..op.args.index("--localrepo") - 1])
          self
        end

        def and_then(op)
          lambda do
            res1 = call
            res2 = op.call
            if res1.is_a?(Array) && res2.is_a?(Array)
              res1 + res2
            else
              [res1, res2]
            end
          end
        end
      end
    end
  end
end
