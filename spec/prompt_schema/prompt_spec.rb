# frozen_string_literal: true

RSpec.describe PromptSchema::Prompt do
  it "renders a prompt" do
    schema = Dry::Schema.Params do
      required(:name).filled(:string)
    end

    prompt = described_class.new(schema)
    result = prompt.call

    expected = <<~PROMPT
      Answer in JSON using this schema:
      {
        name: string,
      }
    PROMPT

    expect(result).to eq(expected)
  end
end
