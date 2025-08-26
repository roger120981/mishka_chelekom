defmodule Mix.Tasks.Mishka.Ui.AddTest do
  use ExUnit.Case
  alias Mix.Tasks.Mishka.Ui.Add

  # Real community JSON structure for testing
  @valid_component_json %{
    "name" => "component_alert_001",
    "author" => "Mona Aghili",
    "type" => "component",
    "files" => [
      %{
        "args" => %{
          "module" => "",
          "only" => ["community_alert_001"],
          "helpers" => %{}
        },
        "name" => "component_alert_001",
        "type" => "component",
        "optional" => [],
        "necessary" => ["alert"],
        "scripts" => [],
        "content" =>
          Base.encode64("""
          defmodule <%= @module %> do
            use Phoenix.Component

            attr(:class, :string, default: nil)

            def community_alert_001(assigns) do
              ~H\"\"\"
              <div class={@class}>
                <p>Attention needed</p>
                <p class="text-xs">Lorem ipsum dolor sit amet.</p>
              </div>
              \"\"\"
            end
          end
          """)
      }
    ]
  }

  describe "GuardedStruct validation" do
    test "validates valid component JSON structure" do
      assert {:ok, params} = Add.builder(@valid_component_json)
      assert params.name == "component_alert_001"
      assert params.type == "component"
      assert length(params.files) == 1

      file = List.first(params.files)
      assert file.name == "component_alert_001"
      assert file.type == "component"
      assert file.necessary == ["alert"]
      assert file.optional == []
    end

    test "validates JavaScript file structure" do
      js_json = %{
        "name" => "js_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "dropdown_script",
            "type" => "javascript",
            "content" => Base.encode64("console.log('Hello');")
          }
        ]
      }

      assert {:ok, params} = Add.builder(js_json)
      file = List.first(params.files)
      assert file.name == "dropdown_script"
      assert file.type == "javascript"
    end

    test "validates preset JSON structure" do
      preset_json = %{
        "name" => "preset_button",
        "type" => "preset",
        "files" => [
          %{
            "name" => "button_preset",
            "type" => "preset",
            "content" => "# Preset content",
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => ["button"],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(preset_json)
      assert params.type == "preset"
      file = List.first(params.files)
      assert file.name == "button_preset"
      assert file.type == "preset"
      assert file.necessary == ["button"]
    end

    test "validates template JSON structure" do
      template_json = %{
        "name" => "template_form",
        "type" => "template",
        "files" => [
          %{
            "name" => "form_template",
            "type" => "template",
            "content" => "# Template content",
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => ["form"],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(template_json)
      assert params.type == "template"
      file = List.first(params.files)
      assert file.name == "form_template"
      assert file.type == "template"
    end

    test "rejects invalid type" do
      invalid_json = %{
        "name" => "test_component",
        # Should be component, preset, template, or javascript
        "type" => "invalid_type",
        "files" => []
      }

      assert {:error, errors} = Add.builder(invalid_json)
      assert is_list(errors)

      assert Enum.any?(errors, fn error ->
               Map.has_key?(error, :field) && error.field == :type
             end)
    end

    test "rejects missing required name field" do
      incomplete_json = %{
        # Missing name field
        "type" => "component",
        "files" => []
      }

      assert {:error, errors} = Add.builder(incomplete_json)
      # The error format is a map, not a list
      assert Map.has_key?(errors, :fields)
      assert "name" in errors.fields
    end

    test "rejects missing required type field" do
      incomplete_json = %{
        "name" => "test_component",
        # Missing type field
        "files" => []
      }

      assert {:error, errors} = Add.builder(incomplete_json)
      # The error format is a map, not a list
      assert Map.has_key?(errors, :fields)
      assert "type" in errors.fields
    end

    test "rejects invalid file structure" do
      invalid_file_json = %{
        "name" => "test_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "test_file",
            # Should be component, preset, template, or javascript
            "type" => "invalid_file_type",
            "content" => "content"
          }
        ]
      }

      assert {:error, errors} = Add.builder(invalid_file_json)
      assert is_list(errors)
      # Should have nested errors for the file validation
      assert Enum.any?(errors, fn error ->
               Map.has_key?(error, :errors) ||
                 (Map.has_key?(error, :field) && error.field == :files)
             end)
    end

    test "rejects files with missing content" do
      no_content_json = %{
        "name" => "test_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "test_file",
            "type" => "component"
            # Missing content field
          }
        ]
      }

      assert {:error, errors} = Add.builder(no_content_json)
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "validates multiple files in single JSON" do
      multi_file_json = %{
        "name" => "multi_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "component_one",
            "type" => "component",
            "content" => "# Component one",
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => [],
            "scripts" => []
          },
          %{
            "name" => "component_two",
            "type" => "component",
            "content" => "# Component two",
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => [],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(multi_file_json)
      assert length(params.files) == 2

      names = Enum.map(params.files, & &1.name)
      assert "component_one" in names
      assert "component_two" in names
    end
  end

  describe "utility functions" do
    test "convert_headers/1 parses header strings correctly" do
      headers = ["Authorization: Bearer token123", "Content-Type: application/json"]
      result = Add.convert_headers(headers)

      assert result == [
               {"Authorization", "Bearer token123"},
               {"Content-Type", "application/json"}
             ]
    end

    test "convert_headers/1 handles headers with spaces" do
      headers = ["X-Custom-Header:   spaced value   ", "Accept:  application/json  "]
      result = Add.convert_headers(headers)

      assert result == [
               {"X-Custom-Header", "spaced value"},
               {"Accept", "application/json"}
             ]
    end

    test "uniq_components?/2 validates unique component names" do
      # Valid case - all unique names
      valid_files = [
        %{name: "component_one"},
        %{name: "component_two"}
      ]

      assert {:ok, :files, ^valid_files} = Add.uniq_components?(:files, valid_files)
    end

    test "uniq_components?/2 rejects duplicate component names" do
      # Invalid case - duplicate names
      invalid_files = [
        %{name: "component_one"},
        %{name: "component_one"}
      ]

      assert {:error, [%{message: msg, field: :files, action: :validator}]} =
               Add.uniq_components?(:files, invalid_files)

      assert String.contains?(msg, "duplicates")
    end

    test "uniq_components?/2 handles empty file list" do
      assert {:ok, :files, []} = Add.uniq_components?(:files, [])
    end

    test "uniq_components?/2 handles single file" do
      single_file = [%{name: "single_component"}]
      assert {:ok, :files, ^single_file} = Add.uniq_components?(:files, single_file)
    end
  end

  describe "Base64 content handling" do
    test "decodes Base64 encoded content" do
      original_content = """
      defmodule TestComponent do
        use Phoenix.Component

        def test(assigns) do
          ~H"<div>Test</div>"
        end
      end
      """

      encoded_content = Base.encode64(original_content)

      # Test with Base64 encoded content
      component_json = %{
        "name" => "test_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "test_component",
            "type" => "component",
            "content" => encoded_content,
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => [],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(component_json)
      file = List.first(params.files)

      # The content should be stored as Base64 in the struct
      assert file.content == encoded_content

      # When decoded, it should match the original
      assert Base.decode64!(file.content) == original_content
    end

    test "handles plain text content (non-Base64)" do
      plain_content = "# Simple plain text content"

      component_json = %{
        "name" => "plain_component",
        "type" => "component",
        "files" => [
          %{
            "name" => "plain_component",
            "type" => "component",
            "content" => plain_content,
            "args" => %{"helpers" => %{}},
            "optional" => [],
            "necessary" => [],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(component_json)
      file = List.first(params.files)
      assert file.content == plain_content
    end
  end

  describe "JSON structure validation edge cases" do
    test "handles empty files array" do
      empty_files_json = %{
        "name" => "empty_component",
        "type" => "component",
        "files" => []
      }

      assert {:ok, params} = Add.builder(empty_files_json)
      assert params.files == []
    end

    test "validates component args structure" do
      component_with_args = %{
        "name" => "component_with_args",
        "type" => "component",
        "files" => [
          %{
            "name" => "rich_component",
            "type" => "component",
            "content" => "# Component content",
            "args" => %{
              "variant" => ["default", "primary"],
              "size" => ["sm", "md", "lg"],
              "color" => ["red", "blue"],
              "helpers" => %{"icon" => "icon_helper"}
            },
            "optional" => ["variant", "size"],
            "necessary" => ["color"],
            "scripts" => []
          }
        ]
      }

      assert {:ok, params} = Add.builder(component_with_args)
      file = List.first(params.files)

      assert file.args.variant == ["default", "primary"]
      assert file.args.size == ["sm", "md", "lg"]
      assert file.args.color == ["red", "blue"]
      # Keys are converted to atoms
      assert file.args.helpers == %{icon: "icon_helper"}
      assert file.optional == ["variant", "size"]
      assert file.necessary == ["color"]
    end

    test "validates file name regex requirements" do
      invalid_name_json = %{
        "name" => "test_component",
        "type" => "component",
        "files" => [
          %{
            # Should only contain lowercase letters, numbers, and underscores
            "name" => "Invalid-Name!",
            "type" => "component",
            "content" => "content"
          }
        ]
      }

      assert {:error, errors} = Add.builder(invalid_name_json)
      assert is_list(errors)
      assert length(errors) > 0
    end

    test "validates string length constraints" do
      long_name_json = %{
        # Exceeds max length of 80
        "name" => String.duplicate("a", 100),
        "type" => "component",
        "files" => []
      }

      assert {:error, errors} = Add.builder(long_name_json)
      assert is_list(errors)

      assert Enum.any?(errors, fn error ->
               Map.has_key?(error, :field) && error.field == :name
             end)
    end

    test "validates minimum string length" do
      short_name_json = %{
        # Below minimum length of 3
        "name" => "ab",
        "type" => "component",
        "files" => []
      }

      assert {:error, errors} = Add.builder(short_name_json)
      assert is_list(errors)

      assert Enum.any?(errors, fn error ->
               Map.has_key?(error, :field) && error.field == :name
             end)
    end
  end
end
