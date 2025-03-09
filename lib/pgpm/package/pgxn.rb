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
        path = "#{self.source.to_s}"
        ["LICENSE", "license", "License"].each do |fn|
          if File.exist?("#{path}/#{fn}")
            return File.read("#{path}/#{fn}")
          end
        end
        nil
      end

    end
  end
end
