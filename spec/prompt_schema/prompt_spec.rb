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
        required(:email).maybe(Types::Email)
        required(:name).filled(:string)
      end
      optional(:items).maybe(:array, min_size?: 1) do
        each(:hash) do
          required(:email).maybe(Types::Email)
        end
      end
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
        items: [
          {
            // An email address
            // @example email@example.com
            email: string or null,
          } or null,
        ],
      }
    PROMPT

    expect(result).to eq(expected)
  end
end
