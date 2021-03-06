# frozen_string_literal: true
require "mobility/backends/active_record"
require "mobility/backends/hash_valued"

module Mobility
  module Backends
=begin

Internal class used by ActiveRecord backends backed by a Postgres data type
(hstore, jsonb).

=end
    class ActiveRecord::PgHash
      include ActiveRecord
      include HashValued

      # @!macro backend_iterator
      def each_locale
        super { |l| yield l.to_sym }
      end

      def translations
        model.read_attribute(attribute)
      end

      setup do |attributes|
        attributes.each { |attribute| store attribute, coder: Coder }
      end

      class Coder
        def self.dump(obj)
          if obj.is_a? Hash
            obj.inject({}) do |translations, (locale, value)|
              translations[locale] = value if value.present?
              translations
            end
          else
            raise ArgumentError, "Attribute is supposed to be a Hash, but was a #{obj.class}. -- #{obj.inspect}"
          end
        end

        def self.load(obj)
          obj
        end
      end
    end
  end
end
