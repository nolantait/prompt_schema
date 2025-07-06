# frozen_string_literal: true

RSpec.describe PromptSchema do
  it "has a version number" do
    expect(PromptSchema::VERSION).not_to be_nil
  end

  describe ".define" do
    it "returns a Schema instance" do
      result = described_class.define do
        required(:name).filled(:string)
      end

      expect(result).to be_a(PromptSchema::Schema)
    end
  end
end
