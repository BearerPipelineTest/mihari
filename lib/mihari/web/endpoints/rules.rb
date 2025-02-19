# frozen_string_literal: true

module Mihari
  module Endpoints
    class Rules < Grape::API
      namespace :rules do
        desc "Search rules", {
          is_array: true,
          success: Entities::Rule,
          failure: [{ code: 404, message: "Not found", model: Entities::Message }],
          summary: "Search rules"
        }
        params do
          optional :page, type: Integer

          optional :title, type: String
          optional :description, type: String
          optional :tag, type: String

          optional :fromAt, type: DateTime
          optional :toAt, type: DateTime
        end
        get "/" do
          filter = params.to_h.to_snake_keys

          # set page & limit
          page = filter["page"] || 1
          filter["page"] = page.to_i

          limit = 10
          filter["limit"] = 10

          # normalize keys
          filter["tag_name"] = filter["tag"]

          # symbolize hash keys
          filter = filter.to_h.symbolize_keys

          search_filter_with_pagenation = Structs::Filters::Rule::SearchFilterWithPagination.new(**filter)
          rules = Mihari::Rule.search(search_filter_with_pagenation)
          total = Mihari::Rule.count(search_filter_with_pagenation.without_pagination)

          present({ rules: rules.map(&:to_h), total: total, current_page: page, page_size: limit }, with: Entities::RulesWithPagination)
        end

        desc "Get a rule", {
          success: Entities::Rule,
          failure: [{ code: 404, message: "Not found", model: Entities::Message }],
          summary: "Get a rule"
        }
        params do
          requires :id, type: String
        end
        get "/:id" do
          id = params["id"].to_s

          begin
            rule = Mihari::Rule.find(id)
          rescue ActiveRecord::RecordNotFound
            error!({ message: "ID:#{id} is not found" }, 404)
          end

          present rule.to_h, with: Entities::Rule
        end

        desc "Run a rule", {
          success: Entities::Message,
          summary: "Run a rule"
        }
        params do
          requires :id, type: String
        end
        get "/:id/run" do
          id = params["id"].to_s

          begin
            rule = Mihari::Rule.find(id)
          rescue ActiveRecord::RecordNotFound
            error!({ message: "ID:#{id} is not found" }, 404)
          end

          struct = Mihari::Structs::Rule.from_model(rule)
          analyzer = struct.to_analyzer
          analyzer.run

          status 201
          present({ message: "ID:#{id} is ran successfully" }, with: Entities::Message)
        end

        desc "Create a rule", {
          success: Entities::Rule,
          summary: "Create a rule"
        }
        params do
          requires :yaml, type: String, documentation: { param_type: "body" }
        end
        post "/" do
          yaml = params[:yaml]

          begin
            rule = Structs::Rule.from_yaml(yaml)
          rescue YAMLSyntaxError => e
            error!({ message: e.message }, 400)
          end

          # check ID duplication
          begin
            Mihari::Rule.find(rule.id)
            error!({ message: "ID:#{rule.id} is already registered" }, 400)
          rescue ActiveRecord::RecordNotFound
            # do nothing
          end

          begin
            rule.validate!
          rescue RuleValidationError
            error!({ message: "Data format is invalid", details: rule.errors.to_h }, 400) if rule.errors?

            # when NoMethodError occurs
            error!({ message: "Data format is invalid" }, 400)
          end

          begin
            model = rule.to_model
            model.save
          rescue ActiveRecord::RecordNotUnique
            error!({ message: "ID:#{rule.id} is already registered" }, 400)
          end

          status 201
          present model.to_h, with: Entities::Rule
        end

        desc "Update a rule", {
          success: Entities::Rule,
          summary: "Update a rule"
        }
        params do
          requires :id, type: String, documentation: { param_type: "body" }
          requires :yaml, type: String, documentation: { param_type: "body" }
        end
        put "/" do
          id = params[:id]
          yaml = params[:yaml]

          begin
            Mihari::Rule.find(id)
          rescue ActiveRecord::RecordNotFound
            error!({ message: "ID:#{id} is not found" }, 404)
          end

          begin
            rule = Structs::Rule.from_yaml(yaml, id: id)
          rescue YAMLSyntaxError => e
            error!({ message: e.message }, 400)
          end

          begin
            rule.validate!
          rescue RuleValidationError
            error!({ message: "Data format is invalid", details: rule.errors.to_h }, 400) if rule.errors?

            # when NoMethodError occurs
            error!({ message: "Data format is invalid" }, 400)
          end

          begin
            model = rule.to_model
            model.save
          rescue ActiveRecord::RecordNotUnique
            error!({ message: "ID:#{model.id} is already registered" }, 400)
          end

          status 201
          present model.to_h, with: Entities::Rule
        end

        desc "Delete a rule", {
          success: Entities::Message,
          failure: [{ code: 404, message: "Not found", model: Entities::Message }],
          summary: "Delete a rule"
        }
        params do
          requires :id, type: String
        end
        delete "/:id" do
          id = params["id"].to_s

          begin
            rule = Mihari::Rule.find(id)
          rescue ActiveRecord::RecordNotFound
            error!({ message: "ID:#{id} is not found" }, 404)
          end

          rule.destroy

          status 204
          present({ message: "ID:#{id} is deleted" }, with: Entities::Message)
        end
      end
    end
  end
end
