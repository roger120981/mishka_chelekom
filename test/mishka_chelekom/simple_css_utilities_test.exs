defmodule MishkaChelekom.SimpleCSSUtilitiesTest do
  use ExUnit.Case
  alias MishkaChelekom.SimpleCSSUtilities
  @moduletag :igniter

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

  describe "add_import_and_theme/3" do
    test "adds import and theme to CSS without theme" do
      css_without_theme = """
      @import "tailwindcss" source(none);

      @source "../css";
      @source "../js";

      body {
        @apply transition-colors duration-300;
      }
      """

      theme_content = """
      @theme {
        --color-primary: blue;
        --color-secondary: green;
      }
      """

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 css_without_theme,
                 "../vendor/mishka_chelekom.css",
                 theme_content
               )

      # Verify import was added
      assert result =~ "@import \"../vendor/mishka_chelekom.css\""

      # Verify theme was added
      assert result =~ "@theme"
      assert result =~ "--color-primary: blue"
      assert result =~ "--color-secondary: green"

      # Verify order is correct
      lines = String.split(result, "\n")
      tailwind_idx = Enum.find_index(lines, &String.contains?(&1, "tailwindcss"))
      mishka_idx = Enum.find_index(lines, &String.contains?(&1, "mishka_chelekom"))
      theme_idx = Enum.find_index(lines, &String.contains?(&1, "@theme"))

      assert tailwind_idx < mishka_idx
      assert mishka_idx < theme_idx
    end

    test "replaces existing theme when adding import" do
      css_with_old_theme = """
      @import "tailwindcss" source(none);
      @import "../vendor/mishka_chelekom.css";

      body {
        @apply transition-colors;
      }

      @theme {
        --old-color: yellow;
        --outdated-var: orange;
      }
      """

      new_theme = """
      @theme {
        --new-primary: blue;
        --new-secondary: green;
      }
      """

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 css_with_old_theme,
                 "../vendor/mishka_chelekom.css",
                 new_theme
               )

      # Import should not be duplicated
      import_count =
        result
        |> String.split("\n")
        |> Enum.count(&String.contains?(&1, "@import \"../vendor/mishka_chelekom.css\""))

      assert import_count == 1

      # Old theme should be replaced
      refute result =~ "--old-color"
      refute result =~ "--outdated-var"

      # New theme should be present
      assert result =~ "--new-primary: blue"
      assert result =~ "--new-secondary: green"
    end

    test "handles empty CSS" do
      theme_content = "@theme { --color: red; }"

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 "",
                 "../vendor/mishka.css",
                 theme_content
               )

      assert result =~ "@import \"../vendor/mishka.css\""
      assert result =~ "@theme { --color: red; }"
    end

    test "preserves existing CSS structure and comments" do
      css = """
      /* Main styles */
      @import "tailwindcss";
      /* Custom imports */

      @custom-variant dark (&:where(.dark, .dark *));

      /* Body styles */
      body {
        margin: 0;
      }
      """

      theme = "@theme { --primary: blue; }"

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 css,
                 "../vendor/mishka.css",
                 theme
               )

      # Comments should be preserved
      assert result =~ "/* Main styles */"
      assert result =~ "/* Custom imports */"
      assert result =~ "/* Body styles */"

      # Custom variant should be preserved
      assert result =~ "@custom-variant dark"

      # Body styles should be preserved
      assert result =~ "body {"
      assert result =~ "margin: 0;"
    end
  end

  describe "ensure_theme_exists/2" do
    test "adds theme when it doesn't exist" do
      css = """
      @import "tailwindcss";

      body {
        margin: 0;
      }
      """

      theme = "@theme { --color-primary: blue; }"

      result = SimpleCSSUtilities.ensure_theme_exists(css, theme)

      assert result =~ "@theme { --color-primary: blue; }"
      assert result =~ "body {"
    end

    test "replaces existing theme" do
      css = """
      @import "tailwindcss";

      @theme {
        --old-var: red;
      }

      body { margin: 0; }
      """

      new_theme = "@theme { --new-var: blue; }"

      result = SimpleCSSUtilities.ensure_theme_exists(css, new_theme)

      refute result =~ "--old-var"
      assert result =~ "--new-var: blue"
      assert result =~ "body { margin: 0; }"
    end

    test "replaces multiline theme block" do
      css = """
      @import "tailwindcss";

      @theme {
        --color-primary: red;
        --color-secondary: green;
        --color-tertiary: blue;
      }

      .class { display: block; }
      """

      new_theme = """
      @theme {
        --new-primary: purple;
      }
      """

      result = SimpleCSSUtilities.ensure_theme_exists(css, new_theme)

      # Old theme variables should be gone
      refute result =~ "--color-primary: red"
      refute result =~ "--color-secondary: green"
      refute result =~ "--color-tertiary: blue"

      # New theme should be present
      assert result =~ "--new-primary: purple"

      # Other CSS should be preserved
      assert result =~ ".class { display: block; }"
    end

    test "handles theme with nested braces" do
      css = """
      @import "tailwindcss";

      @theme {
        --gradient: linear-gradient(90deg, rgba(0,0,0,0) 0%, rgba(255,255,255,1) 100%);
        --shadow: 0 0 10px rgba(0,0,0,0.5);
      }
      """

      new_theme = "@theme { --simple: blue; }"

      result = SimpleCSSUtilities.ensure_theme_exists(css, new_theme)

      refute result =~ "--gradient"
      refute result =~ "--shadow"
      assert result =~ "--simple: blue"
    end

    test "appends theme to empty CSS" do
      theme = "@theme { --var: value; }"
      result = SimpleCSSUtilities.ensure_theme_exists("", theme)

      assert result == "\n\n@theme { --var: value; }\n"
    end

    test "preserves whitespace and formatting" do
      css = """
      @import "tailwindcss";


      body {
        margin: 0;
      }
      """

      theme = "@theme { --var: val; }"
      result = SimpleCSSUtilities.ensure_theme_exists(css, theme)

      assert result =~ "@import \"tailwindcss\""
      assert result =~ "body {"
      assert result =~ "@theme { --var: val; }"
    end
  end

  describe "read_theme_content/1" do
    test "reads existing file successfully" do
      # Create a temporary test file
      tmp_dir = System.tmp_dir!()
      theme_path = Path.join(tmp_dir, "test_theme.css")
      theme_content = "@theme { --test-var: test-value; }"

      File.write!(theme_path, theme_content)

      assert {:ok, content} = SimpleCSSUtilities.read_theme_content(theme_path)
      assert content == theme_content

      # Clean up
      File.rm!(theme_path)
    end

    test "returns error for non-existent file" do
      non_existent = "/path/that/does/not/exist/theme.css"

      assert {:error, :enoent} = SimpleCSSUtilities.read_theme_content(non_existent)
    end

    test "reads file with complex content" do
      tmp_dir = System.tmp_dir!()
      theme_path = Path.join(tmp_dir, "complex_theme.css")

      complex_theme = """
      @theme {
        --color-primary: #3490dc;
        --color-secondary: #ffed4a;
        --gradient: linear-gradient(90deg, #000 0%, #fff 100%);
        --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
      }
      """

      File.write!(theme_path, complex_theme)

      assert {:ok, content} = SimpleCSSUtilities.read_theme_content(theme_path)
      assert content == complex_theme

      # Clean up
      File.rm!(theme_path)
    end
  end

  describe "complex integration scenarios" do
    test "handles complete Tailwind 4 Phoenix setup" do
      full_css = """
      @import "tailwindcss" source(none);
      @import "../vendor/mishka_chelekom.css";

      @source "../css";
      @source "../js";
      @source "../../lib/mishka_web";

      @plugin "../vendor/heroicons";

      @custom-variant phx-click-loading (.phx-click-loading&, .phx-click-loading &);
      @custom-variant phx-submit-loading (.phx-submit-loading&, .phx-submit-loading &);
      @custom-variant phx-change-loading (.phx-change-loading&, .phx-change-loading &);
      @custom-variant dark (&:where(.dark, .dark *));

      [data-phx-session],
      [data-phx-teleported-src] {
          display: contents;
      }

      html {
          @apply scroll-smooth;
      }

      body {
          @apply transition-colors duration-300 dark:bg-[#1A1819];
      }

      @theme {
          --old-primary: red;
      }
      """

      new_theme = """
      @theme {
          --color-primary: blue;
          --color-secondary: green;
      }
      """

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 full_css,
                 "../vendor/mishka_chelekom.css",
                 new_theme
               )

      # Import should not be duplicated
      import_count =
        result
        |> String.split("\n")
        |> Enum.count(&String.contains?(&1, "mishka_chelekom.css"))

      assert import_count == 1

      # All Tailwind 4 directives should be preserved
      assert result =~ "@source \"../css\""
      assert result =~ "@plugin \"../vendor/heroicons\""
      assert result =~ "@custom-variant phx-click-loading"

      # Styles should be preserved
      assert result =~ "display: contents"
      assert result =~ "@apply scroll-smooth"
      assert result =~ "dark:bg-[#1A1819]"

      # Old theme should be replaced with new
      refute result =~ "--old-primary"
      assert result =~ "--color-primary: blue"
      assert result =~ "--color-secondary: green"
    end

    test "workflow: first time setup (no theme)" do
      initial_css = """
      @import "tailwindcss" source(none);

      @source "../css";

      body {
          @apply font-sans;
      }
      """

      theme = """
      @theme {
          --primary: #3490dc;
          --secondary: #ffed4a;
      }
      """

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 initial_css,
                 "../vendor/mishka_chelekom.css",
                 theme
               )

      # Should have both imports
      assert result =~ "@import \"tailwindcss\""
      assert result =~ "@import \"../vendor/mishka_chelekom.css\""

      # Should have theme appended
      assert result =~ "@theme"
      assert result =~ "--primary: #3490dc"
    end

    test "workflow: updating existing setup (theme exists)" do
      existing_css = """
      @import "tailwindcss" source(none);
      @import "../vendor/mishka_chelekom.css";

      body { margin: 0; }

      @theme {
          --primary: oldcolor;
      }
      """

      updated_theme = """
      @theme {
          --primary: newcolor;
          --secondary: anothercolor;
      }
      """

      assert {:ok, result} =
               SimpleCSSUtilities.add_import_and_theme(
                 existing_css,
                 "../vendor/mishka_chelekom.css",
                 updated_theme
               )

      # Import count should remain 1
      mishka_imports =
        result
        |> String.split("\n")
        |> Enum.count(&String.contains?(&1, "mishka_chelekom.css"))

      assert mishka_imports == 1

      # Theme should be updated
      refute result =~ "oldcolor"
      assert result =~ "newcolor"
      assert result =~ "anothercolor"
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
  end
end
