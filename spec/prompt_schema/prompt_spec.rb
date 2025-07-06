# frozen_string_literal: true

RSpec.describe PromptSchema::Prompt do
  before do
    stub_const(
      "Types::Email",
      Dry::Types["string"].meta(
        description: "An email address",
        example: "email@example.com"
      )
    )
  end

  it "renders a prompt" do
    schema = Dry::Schema.Params do
      required(:email).maybe(type?: Types::Email)
      required(:name).filled(:string)
    end

    prompt = described_class.new(schema)
    result = prompt.call

    expected = <<~PROMPT
      Answer in JSON using this schema:
      {
        // An email address
        // @example email@example.com
        email: string or null,
        name: string,
      }
    PROMPT

    expect(result).to eq(expected)
  end
end
