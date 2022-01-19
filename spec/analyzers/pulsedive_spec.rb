# frozen_string_literal: true

RSpec.describe Mihari::Analyzers::Pulsedive, :vcr do
  context "when given an ipv4" do
    subject { described_class.new(query) }

    let(:query) { "1.1.1.1" }

    describe "#artifacts" do
      it do
        expect(subject.artifacts).to be_an(Array)
      end
    end
  end

  context "when given a domain" do
    subject { described_class.new(query) }

    let(:query) { "one.one.one.one" }

    describe "#artifacts" do
      it do
        expect(subject.artifacts).to be_an(Array)
      end
    end
  end

  context "when given an invalid input" do
    subject { described_class.new(query) }

    let(:query) { "foo bar" }

    describe "#artifacts" do
      it do
        expect { subject.artifacts }.to raise_error(Mihari::InvalidInputError)
      end
    end
  end

  context "when api config is not given" do
    before do
      allow(Mihari.config).to receive(:pulsedive_api_key).and_return(nil)
    end

    it do
      expect { subject.artifacts }.to raise_error(ArgumentError)
    end
  end
end
