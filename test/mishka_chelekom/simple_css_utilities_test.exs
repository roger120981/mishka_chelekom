defmodule MishkaChelekom.SimpleCSSUtilitiesTest do
  use ExUnit.Case
  alias MishkaChelekom.SimpleCSSUtilities

  describe "add_import/3" do
    test "adds import to empty CSS" do
      assert {:ok, :added, result} = SimpleCSSUtilities.add_import("", "../vendor/mishka.css")
      assert result == "@import \"../vendor/mishka.css\";\n"
    end

    test "adds import after existing imports" do
      css = "@import \"tailwindcss\";"
      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"tailwindcss\";"
      assert result =~ "@import \"../vendor/mishka.css\";"
    end

    test "detects existing import" do
      css = "@import \"../vendor/mishka.css\";"
      assert {:ok, :exists, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result == css
    end

    test "detects existing import with different quotes" do
      css = "@import '../vendor/mishka.css';"
      assert {:ok, :exists, _result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "detects existing import with url()" do
      css = "@import url(\"../vendor/mishka.css\");"
      assert {:ok, :exists, _result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "handles Tailwind 4 import syntax with source(none)" do
      css = "@import \"tailwindcss\" source(none);"
      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"../vendor/mishka.css\";"
    end

    test "adds import after multiple existing imports" do
      css = """
      @import "tailwindcss";
      @import "fonts.css";
      """

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"../vendor/mishka.css\";"

      lines = String.split(result, "\n")
      import_lines = Enum.filter(lines, &String.contains?(&1, "@import"))
      assert length(import_lines) == 3
      assert List.last(import_lines) =~ "mishka.css"
    end

    test "handles Tailwind 4 full configuration" do
      css = """
      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/mishka_web";

      @plugin "../vendor/heroicons";

      /* Add variants based on LiveView classes */
      @custom-variant phx-click-loading (.phx-click-loading&, .phx-click-loading &);
      @custom-variant phx-submit-loading (.phx-submit-loading&, .phx-submit-loading &);
      @custom-variant phx-change-loading (.phx-change-loading&, .phx-change-loading &);

      /* Use the data attribute for dark mode  */
      @custom-variant dark (&:where(.dark, .dark *));

      /* Make LiveView wrapper divs transparent for layout */
      [data-phx-session],
      [data-phx-teleported-src] {
          display: contents;
      }
      """

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")

      # Should add after the @import "tailwindcss" line
      lines = String.split(result, "\n")

      import_indices =
        lines
        |> Enum.with_index()
        |> Enum.filter(fn {line, _} -> String.contains?(line, "@import") end)
        |> Enum.map(fn {_, idx} -> idx end)

      assert length(import_indices) == 2
      assert lines |> Enum.at(List.first(import_indices)) |> String.contains?("tailwindcss")
      assert lines |> Enum.at(List.last(import_indices)) |> String.contains?("mishka.css")
    end

    test "adds import after @source directives when no imports exist" do
      css = """
      @source "../css";
      @source "../js";

      body { margin: 0; }
      """

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")

      assert result =~ "@import \"../vendor/mishka.css\";"
      # The import should be added after source directives
      assert result =~ ~r/@source.*@import/s
    end

    test "normalizes paths with backslashes" do
      css = "@import \"../vendor/mishka.css\";"
      assert {:ok, :exists, _} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "normalizes paths with double slashes" do
      css = "@import \"../vendor/mishka.css\";"
      assert {:ok, :exists, _} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "handles CSS with comments" do
      css = """
      /* Main stylesheet */
      @import "tailwindcss";
      /* Custom components */
      """

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"../vendor/mishka.css\";"
      assert result =~ "/* Main stylesheet */"
      assert result =~ "/* Custom components */"
    end

    test "handles malformed CSS gracefully" do
      css = "@import \"unclosed"

      # Should still try to add the import
      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"../vendor/mishka.css\";"
    end
  end

  describe "import_already_exists?/2" do
    test "detects import with double quotes" do
      css = "@import \"../vendor/mishka.css\";"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "detects import with single quotes" do
      css = "@import '../vendor/mishka.css';"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "detects import with url() and double quotes" do
      css = "@import url(\"../vendor/mishka.css\");"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "detects import with url() and single quotes" do
      css = "@import url('../vendor/mishka.css');"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "detects import with url() and no quotes" do
      css = "@import url(../vendor/mishka.css);"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "detects Tailwind 4 import with source modifier" do
      css = "@import \"../vendor/mishka.css\" source(none);"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "returns false for non-existing import" do
      css = "@import \"other.css\";"
      refute SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "handles normalized paths" do
      css = "@import \"../vendor/mishka.css\";"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end

    test "is case insensitive for @import keyword" do
      css = "@IMPORT \"../vendor/mishka.css\";"
      assert SimpleCSSUtilities.import_already_exists?(css, "../vendor/mishka.css")
    end
  end

  describe "validate_tailwind_structure/1" do
    test "validates correct Tailwind 4 structure" do
      css = """
      @import "tailwindcss";
      @import "../vendor/mishka.css";
      """

      assert :ok = SimpleCSSUtilities.validate_tailwind_structure(css)
    end

    test "detects when tailwindcss import is not first" do
      css = "@import \"../vendor/mishka.css\";\n@import \"tailwindcss\";"

      assert {:error, errors} = SimpleCSSUtilities.validate_tailwind_structure(css)
      assert "@import 'tailwindcss' should come before other imports" in errors
    end

    test "allows tailwindcss with source modifier" do
      css = """
      @import "tailwindcss" source(none);
      @import "../vendor/mishka.css";
      """

      assert :ok = SimpleCSSUtilities.validate_tailwind_structure(css)
    end

    test "validates empty CSS" do
      assert :ok = SimpleCSSUtilities.validate_tailwind_structure("")
    end

    test "validates CSS without imports" do
      css = """
      body {
        margin: 0;
      }
      """

      assert :ok = SimpleCSSUtilities.validate_tailwind_structure(css)
    end
  end

  describe "insert_import/2" do
    test "inserts at beginning of empty CSS" do
      result = SimpleCSSUtilities.insert_import("", "../vendor/mishka.css")
      assert result == "@import \"../vendor/mishka.css\";\n"
    end

    test "inserts at beginning when no directives exist" do
      css = "body { margin: 0; }"
      result = SimpleCSSUtilities.insert_import(css, "../vendor/mishka.css")
      assert result == "@import \"../vendor/mishka.css\";\n\nbody { margin: 0; }"
    end

    test "inserts after last import" do
      css = """
      @import "first.css";
      @import "second.css";
      body { margin: 0; }
      """

      result = SimpleCSSUtilities.insert_import(css, "../vendor/mishka.css")
      lines = String.split(result, "\n")

      import_lines = Enum.filter(lines, &String.contains?(&1, "@import"))
      assert length(import_lines) == 3
      assert List.last(import_lines) =~ "mishka.css"
    end

    test "inserts after @source when no imports exist" do
      css = """
      @source "../css";
      @source "../js";
      """

      result = SimpleCSSUtilities.insert_import(css, "../vendor/mishka.css")

      assert result =~ "@import \"../vendor/mishka.css\";"
      # The import should be added after source directives
      assert result =~ ~r/@source.*@import/s
    end

    test "respects directive priorities" do
      css = """
      @plugin "../vendor/heroicons";
      @custom-variant dark (&:where(.dark, .dark *));
      """

      result = SimpleCSSUtilities.insert_import(css, "../vendor/mishka.css")
      lines = String.split(result, "\n")

      plugin_idx = lines |> Enum.find_index(&String.contains?(&1, "@plugin"))
      import_idx = lines |> Enum.find_index(&String.contains?(&1, "@import"))

      assert plugin_idx < import_idx
    end

    test "handles spacing correctly" do
      css = "@import \"first.css\";\n\nbody { margin: 0; }"
      result = SimpleCSSUtilities.insert_import(css, "../vendor/mishka.css")

      # Should have proper spacing
      assert result =~ "@import \"first.css\";"
      assert result =~ "@import \"../vendor/mishka.css\";"
      assert result =~ "body { margin: 0; }"
    end
  end

  describe "edge cases" do
    test "handles multiple consecutive spaces" do
      css = "@import     \"../vendor/mishka.css\";"
      assert {:ok, :exists, _} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "handles tabs instead of spaces" do
      css = "@import\t\"../vendor/mishka.css\";"
      assert {:ok, :exists, _} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
    end

    test "handles mixed line endings" do
      css = "@import \"first.css\";\r\n@import \"second.css\";\n"
      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "mishka.css"
    end

    test "handles CSS with @theme block" do
      css = """
      @import "tailwindcss";
      @theme {
        --color-primary: #3490dc;
        --color-secondary: #ffed4a;
      }
      """

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, "../vendor/mishka.css")
      assert result =~ "@import \"../vendor/mishka.css\";"

      # Should be after the tailwindcss import but before @theme
      lines = String.split(result, "\n")
      tailwind_idx = Enum.find_index(lines, &String.contains?(&1, "tailwindcss"))
      mishka_idx = Enum.find_index(lines, &String.contains?(&1, "mishka.css"))
      theme_idx = Enum.find_index(lines, &String.contains?(&1, "@theme"))

      assert tailwind_idx < mishka_idx
      assert mishka_idx < theme_idx
    end

    test "handles very long paths" do
      long_path = "../" <> String.duplicate("very/long/", 20) <> "path.css"
      css = "@import \"#{long_path}\";"

      assert {:ok, :exists, _} = SimpleCSSUtilities.add_import(css, long_path)
    end

    test "handles special characters in paths" do
      path = "../vendor/mishka-chelekom_v1.0.css"
      css = ""

      assert {:ok, :added, result} = SimpleCSSUtilities.add_import(css, path)
      assert result =~ "@import \"#{path}\";"
    end
  end
end
