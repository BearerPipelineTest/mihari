# frozen_string_literal: true

module Mihari
  module Commands
    module Search
      include Mixins::Database
      include Mixins::ErrorNotification

      def self.included(thor)
        thor.class_eval do
          desc "search [RULE]", "Search by a rule"
          method_option :yes, type: :boolean, aliases: "-y", desc: "yes to overwrite the rule in the database"
          def search_by_rule(path_or_id)
            rule = Structs::Rule.from_path_or_id path_or_id

            # validate
            rule.validate!

            # check update
            id = rule.id
            yes = options["yes"] || false
            unless yes
              with_db_connection do
                rule_ = Mihari::Rule.find(id)
                next if rule.yaml == rule_.yaml
                return unless yes?("This operation will overwrite the rule in the database (Rule ID: #{id}). Are you sure you want to update the rule? (yes/no)")
              rescue ActiveRecord::RecordNotFound
                next
              end
            end

            analyzer = rule.to_analyzer

            with_error_notification do
              alert = analyzer.run

              if alert
                data = Mihari::Entities::Alert.represent(alert)
                puts JSON.pretty_generate(data.as_json)
              else
                Mihari.logger.info "There is no new artifact"
              end

              # record a rule
              with_db_connection do
                model = rule.to_model
                model.save
              rescue ActiveRecord::RecordNotUnique
                nil
              end
            end
          end
        end
      end
    end
  end
end
