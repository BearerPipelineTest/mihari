# frozen_string_literal: true

module Mihari
  module Mixins
    module Configurable
      #
      # Check whether it is configured or not
      #
      # @return [Boolean]
      #
      def configured?
        return true if configuration_keys.empty?

        configuration_keys.all? { |key| Mihari.config.send(key) } || api_key?
      end

      #
      # Configuration values
      #
      # @return [Array<Hash>, nil] Configuration values as a list of hash. Returns nil if there is any keys.
      #
      def configuration_values
        return nil if configuration_keys.empty?

        configuration_keys.map do |key|
          { key: key.upcase, value: Mihari.config.send(key) }
        end
      end

      #
      # Configuration keys
      #
      # @return [Array<String>] A list of cofiguration keys
      #
      def configuration_keys
        []
      end

      private

      def api_key?
        value = method(:api_key).call
        !value.nil?
      rescue NameError
        true
      end
    end
  end
end
