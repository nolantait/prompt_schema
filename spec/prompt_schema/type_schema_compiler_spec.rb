# frozen_string_literal: true

RSpec.describe PromptSchema::TypeSchemaCompiler do
  it "returns a hash of metadata" do
    schema = Dry::Schema.Params do
      required(:name).filled(Dry::Types["nominal.string"].meta(description: "The name of the person"))
      required(:address).hash do
        required(:street).filled(Dry::Types["nominal.string"].meta(something: "Something", description: "Street address"))
      end
      required(:hobbies).array(:hash) do
        required(:name).filled(Dry::Types["nominal.string"].meta(description: "Hobby name"))
        optional(:tags).array(:hash) do
          required(:name).filled(Dry::Types["nominal.string"].meta(description: "Tag name"))
        end
      end
    end

    result = subject.call(schema.type_schema.to_ast)

    expect(result).to eq(
      {
        name: {
          required: false,
          type: "string",
          description: "The name of the person",
          maybe: false
        },
        address: {
          required: false,
          street: {
            required: false,
            type: "string",
            description: "Street address",
            something: "Something",
            maybe: false
          }
        },
        hobbies: {
          required: false,
          type: "array",
          maybe: false,
          items: {
            name: {
              required: false,
              type: "string",
              description: "Hobby name",
              maybe: false
            },
            tags: {
              required: false,
              type: "array",
              maybe: false,
              items: {
                name: {
                  required: false,
                  type: "string",
                  description: "Tag name",
                  maybe: false
                }
              }
            }
          }
        }
      }
    )
  end
end
