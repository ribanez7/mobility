module Mobility
  module Backends
=begin

Defines read and write methods that access the value at a key with value
+locale+ on a +translations+ hash.

=end
    module HashValued
      # @!group Backend Accessors
      #
      # @!macro backend_reader
      def read(locale, _options = nil)
        translations[locale]
      end

      # @!macro backend_writer
      def write(locale, value, _options = nil)
        translations[locale] = value
      end
      # @!endgroup

      # @!macro backend_iterator
      def each_locale
        translations.each { |l, _| yield l }
      end
    end
  end
end
