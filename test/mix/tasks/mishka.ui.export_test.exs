defmodule Mix.Tasks.Mishka.Ui.ExportTest do
  use ExUnit.Case
  import Igniter.Test

  describe "template creation" do
    test "creates default JSON template when --template flag is used" do
      test_dir = Path.join(System.tmp_dir!(), "test_template_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--template"])

      # Find the template file - it might have a relative path key
      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert json["name"] == "something-new"
      assert json["type"] == "preset"
      assert is_list(json["files"])
      assert length(json["files"]) == 1

      file = List.first(json["files"])
      assert file["type"] == "component"
      assert file["name"] == "last_message"
      assert Map.has_key?(file, "args")
      assert is_list(file["optional"])
      assert is_list(file["necessary"])
    end

    test "creates template with custom name" do
      test_dir = Path.join(System.tmp_dir!(), "test_custom_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--template", "--name", "custom"])

      # Find the custom file
      custom_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "custom.json"), do: key
        end)

      assert custom_file_key
      source = igniter.rewrite.sources[custom_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert json["name"] == "something-new"
    end
  end

  describe "directory validation" do
    test "reports error when directory doesn't exist" do
      non_existent_dir = "/path/that/does/not/exist"

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [non_existent_dir])

      # Issues in igniter are strings
      assert Enum.any?(igniter.issues, fn issue ->
               is_binary(issue) && issue == "The entered directory does not exist."
             end)
    end
  end

  describe "JavaScript file export" do
    test "exports JavaScript files with component files" do
      test_dir = Path.join(System.tmp_dir!(), "test_js_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Create a valid component first to avoid validation error
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([component_test: [name: "test", args: []]])
      )

      # Add JavaScript file
      js_content = "console.log('Hello from component');"
      File.write!(Path.join(test_dir, "button_script.js"), js_content)

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir])

      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      # Should have both component and JavaScript files
      assert length(json["files"]) == 2

      js_file = Enum.find(json["files"], &(&1["type"] == "javascript"))
      assert js_file["name"] == "button_script"
      assert js_file["content"] == js_content
    end

    test "exports JavaScript with Base64 encoding" do
      test_dir = Path.join(System.tmp_dir!(), "test_js_base64_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Create a valid component first
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([component_test: [name: "test", args: []]])
      )

      # Add JavaScript file
      js_content = "console.log('Special: éñüçh');"
      File.write!(Path.join(test_dir, "special.js"), js_content)

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--base64"])

      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      json_content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(json_content)

      js_file = Enum.find(json["files"], &(&1["type"] == "javascript"))
      encoded_content = js_file["content"]

      # Verify it's Base64 encoded
      refute encoded_content == js_content
      assert Base.decode64!(encoded_content) == js_content
    end
  end

  describe "component validation" do
    test "requires matching .exs and .eex files" do
      test_dir = Path.join(System.tmp_dir!(), "validation_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Create only .eex file without corresponding .exs
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir])

      # Should have validation error about missing .exs file
      assert Enum.any?(igniter.issues, fn issue ->
               is_binary(issue) && String.contains?(issue, "problems with the file list")
             end)
    end

    test "accepts valid component file pairs" do
      test_dir = Path.join(System.tmp_dir!(), "valid_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Create matching .exs and .eex files
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test Component</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([
          component_test: [
            name: "test_component",
            args: [variant: ["outline", "solid"]]
          ]
        ])
      )

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir])

      # Should create JSON file successfully
      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert length(json["files"]) == 1
      file = List.first(json["files"])
      assert file["type"] == "component"
      assert file["name"] == "test_component"
      assert file["content"] == "<div>Test Component</div>"
    end
  end

  describe "options" do
    test "uses custom name option" do
      test_dir = Path.join(System.tmp_dir!(), "test_name_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Add a valid component first
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([component_test: [name: "test", args: []]])
      )

      File.write!(Path.join(test_dir, "test.js"), "// test content")

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--name", "my_export"])

      my_export_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "my_export.json"), do: key
        end)

      assert my_export_file_key
      source = igniter.rewrite.sources[my_export_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert json["name"] == "my_export"
    end

    test "uses custom org option" do
      test_dir = Path.join(System.tmp_dir!(), "test_org_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Add a valid component first
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([component_test: [name: "test", args: []]])
      )

      File.write!(Path.join(test_dir, "test.js"), "// test content")

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--org", "preset"])

      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert json["type"] == "preset"
    end

    test "defaults invalid org to component" do
      test_dir = Path.join(System.tmp_dir!(), "test_org_invalid_#{:rand.uniform(100_000)}")
      File.mkdir_p!(test_dir)
      on_exit(fn -> File.rm_rf!(test_dir) end)

      # Add a valid component first
      File.write!(Path.join(test_dir, "component_test.eex"), "<div>Test</div>")

      File.write!(
        Path.join(test_dir, "component_test.exs"),
        ~s([component_test: [name: "test", args: []]])
      )

      File.write!(Path.join(test_dir, "test.js"), "// test content")

      igniter =
        test_project()
        |> Igniter.compose_task("mishka.ui.export", [test_dir, "--org", "invalid_type"])

      template_file_key =
        Enum.find_value(igniter.rewrite.sources, fn {key, _} ->
          if String.ends_with?(key, "template.json"), do: key
        end)

      assert template_file_key
      source = igniter.rewrite.sources[template_file_key]
      content = Rewrite.Source.get(source, :content)
      json = Jason.decode!(content)

      assert json["type"] == "component"
    end
  end
end
