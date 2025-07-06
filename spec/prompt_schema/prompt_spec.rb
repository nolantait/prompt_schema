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
      required(:user).hash do
        required(:email).maybe(type?: Types::Email)
        required(:name).filled(:string)
      end
      optional(:items).value(:array, min_size?: 1).each(type?: Types::Email)
    end

    prompt = described_class.new(schema)
    result = prompt.call

    expected = <<~PROMPT
      Answer in JSON using this schema:
      {
        user: {
          // An email address
          // @example email@example.com
          email: string or null,
          name: string,
        },
        // must be an array with at least 1 item
        items: [
          {
            // An email address
            // @example email@example.com
            email: string,
          } or null,
        ],
      }
    PROMPT

    expect(result).to eq(expected)
  end
end
