# frozen_string_literal: true

module Pgpm
  class Package
    module Metadata
      def summary
        "TODO: summary"
      end

      def description
        "TODO: description"
      end

      def all_searchable_texts
        [name, summary, description]
      end

      def license
        "TODO: license"
      end

      def broken?
        requires.any?(&:broken?)
      end

      module ClassMethods
        def extension_name
          self[:latest]&.extension_name
        end

        def description
          self[:latest]&.description
        end

        def summary
          self[:latest]&.summary
        end

        def license
          self[:latest]&.license
        end

        def all_searchable_texts
          self[:latest]&.all_searchable_texts || []
        end
      end

      def self.included(base_class)
        base_class.extend(ClassMethods)
      end
    end
  end
end
