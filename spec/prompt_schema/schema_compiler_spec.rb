# frozen_string_literal: true

RSpec.describe PromptSchema::SchemaCompiler do
  before do
    stub_const(
      "Types::Email", Dry::Types["strict.string"].meta(
        description: "An email address",
        example: "email@example.com"
      )
    )
    stub_const(
      "Types::User", Dry::Types["strict.hash"].schema(
        email: Types::Email
      )
    )
  end

  it "compiles a simple schema AST to a hash" do
    schema = Dry::Schema.Params do
      required(:name).filled(:string)
    end

    result = described_class.call(schema)

    expected = {
      keys: {
        name: {
          type: "string",
          required: true,
          nullable: false
        }
      }
    }

    expect(result).to eq(expected)
  end

  it "compiles a type with metadata as a nested hash" do
    sub_schema = Dry::Schema.Params do
      required(:email).value(Types::Email)
    end

    schema = Dry::Schema.Params do
      required(:user).hash(sub_schema)
    end

    result = described_class.call(schema)

    expected = {
      keys: {
        user: {
          type: "hash",
          required: true,
          nullable: false,
          keys: {
            email: {
              type: "string",
              required: true,
              nullable: false,
              example: "email@example.com",
              description: "An email address"
            }
          }
        }
      }
    }

    expect(result).to eq(expected)
  end

  it "compiles a type with metadata in an array" do
    sub_schema = Dry::Schema.Params do
      required(:email).value(type?: Types::Email)
    end

    schema = Dry::Schema.Params do
      required(:strings).value(:array).each(type?: Types::Email)
      optional(:items).value(:array).each(type?: sub_schema)
    end

    result = described_class.call(schema)

    expected = {
      keys: {
        strings: {
          type: "array",
          required: true,
          nullable: false,
          description: "An email address",
          example: "email@example.com",
          member: "string"
        },
        items: {
          type: "array",
          required: false,
          nullable: false,
          member: {
            keys: {
              email: {
                type: "string",
                required: true,
                nullable: false,
                example: "email@example.com",
                description: "An email address"
              }
            }
          }
        }
      }
    }

    expect(result).to eq(expected)
  end
end
