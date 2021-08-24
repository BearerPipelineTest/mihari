# frozen_string_literal: true

require "active_record"
require "active_record/filter"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/numeric/time"
require "uri"

class ArtifactValidator < ActiveModel::Validator
  def validate(record)
    return if record.data_type

    record.errors.add :data, "#{record.data} is not supported"
  end
end

module Mihari
  class Artifact < ActiveRecord::Base
    has_one :autonomous_system, dependent: :destroy
    has_one :geolocation, dependent: :destroy
    has_one :whois_record, dependent: :destroy

    has_many :dns_records, dependent: :destroy
    has_many :reverse_dns_names, dependent: :destroy

    include ActiveModel::Validations

    validates_with ArtifactValidator

    def initialize(attributes)
      super

      self.data_type = TypeChecker.type(data)
    end

    #
    # Check uniqueness of artifact
    #
    # @param [Boolean] ignore_old_artifacts
    # @param [Integer] ignore_threshold
    #
    # @return [Boolean] true if it is unique. Otherwise false.
    #
    def unique?(ignore_old_artifacts: false, ignore_threshold: 0)
      artifact = self.class.where(data: data).order(created_at: :desc).first
      return true if artifact.nil?

      return false unless ignore_old_artifacts

      days_before = (-ignore_threshold).days.from_now.utc
      # if an artifact is created before {ignore_threshold} days, ignore it
      #                           within {ignore_threshold} days, do not ignore it
      artifact.created_at < days_before
    end

    #
    # Enrich(add) whois record
    #
    def enrich_whois
      return unless can_enrich_whois?

      self.whois_record = WhoisRecord.build_by_domain(normalize_as_domain(data))
    end

    #
    # Enrich(add) DNS records
    #
    def enrich_dns
      return unless can_enrich_dns?

      self.dns_records = DnsRecord.build_by_domain(normalize_as_domain(data))
    end

    #
    # Enrich(add) reverse DNS names
    #
    def enrich_reverse_dns
      return unless can_enrich_revese_dns?

      self.reverse_dns_names = ReverseDnsName.build_by_ip(data)
    end

    private

    def normalize_as_domain(url_or_domain)
      return url_or_domain if data_type == "domain"

      URI.parse(url_or_domain).host
    end

    def can_enrich_whois?
      %w[domain url].include? data_type
    end

    def can_enrich_dns?
      %w[domain url].include? data_type
    end

    def can_enrich_revese_dns?
      data_type == "ip"
    end
  end
end
