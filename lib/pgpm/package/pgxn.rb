# frozen_string_literal: true

require "oj"

module Pgpm
  class Package
    module PGXN
      def provides_pgxn_meta_json?
        File.directory?(source) && File.file?(pgxn_meta_json_path)
      end

      def pgxn_meta_json
        @pgxn_meta_json ||= Oj.load(File.read(pgxn_meta_json_path))
      end

      def pgxn_meta_json_path
        source.join("META.json")
      end

      def extension_name
        if provides_pgxn_meta_json?
          pgxn_meta_json["name"]
        else
          super
        end
      end

      def summary
        if provides_pgxn_meta_json?
          pgxn_meta_json["abstract"]
        else
          super
        end
      end

      def description
        if provides_pgxn_meta_json?
          pgxn_meta_json["description"]
        else
          super
        end
      end

      def license
        if provides_pgxn_meta_json?
          lic = pgxn_meta_json["license"]
          case lic
          when Hash
            lic.keys.join(" or ")
          when Array
            lic.join(" or ")
          when String
            lic
          end
        else
          super
        end
      end

      def license_text
        path = source.to_s
        %w[license lisence unlicense unlisence copying].each do |fn|
          [fn, fn.capitalize, fn.upcase].each do |fn2|
            ["", ".txt", ".md"].each do |fn3|
              if File.exist?("#{path}/#{fn2}#{fn3}")
                return File.read("#{path}/#{fn2}#{fn3}")
              end
            end
          end
        end
        nil
      end
    end
  end
end
