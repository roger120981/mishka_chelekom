defmodule Mix.Tasks.Mishka.Ui.Css.ConfigWorkingTest do
  use ExUnit.Case
  import Igniter.Test
  alias Mix.Tasks.Mishka.Ui.Css.Config

  setup do
    # Ensure Owl is started
    Application.ensure_all_started(:owl)
    
    # DO NOT DELETE REAL LIBRARY FILES!
    # Tests should only clean up test-specific directories
    # The test_project() creates an isolated test environment
    
    :ok
  end

  describe "mix mishka.ui.css.config --init" do
    test "creates config file when it doesn't exist" do
      igniter = 
        test_project()
        |> Igniter.compose_task(Config, ["--init"])
      
      # Should create the config file
      assert_creates(igniter, "priv/mishka_chelekom/config.exs")
      
      # Check notices contain expected text
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "Created configuration file")
    end

    test "does not overwrite existing config without --force" do
      # Create existing config in the test project
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", "# Existing")
        |> Igniter.compose_task(Config, ["--init"])
      
      # Should NOT overwrite
      assert_unchanged(igniter, "priv/mishka_chelekom/config.exs")
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "already exists")
    end

    test "overwrites with --force flag" do
      # Create existing config in test project
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", "# Old content")
        |> Igniter.compose_task(Config, ["--init", "--force"])
      
      # Should create new file (overwrite)
      assert_creates(igniter, "priv/mishka_chelekom/config.exs")
      
      # Verify content changed by checking the actual file created
      assert igniter.rewrite.sources["priv/mishka_chelekom/config.exs"]
      source = igniter.rewrite.sources["priv/mishka_chelekom/config.exs"]
      content = Rewrite.Source.get(source, :content)
      
      refute String.contains?(content, "# Old content")
      assert String.contains?(content, "# Mishka Chelekom CSS Configuration")
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "overwritten")
    end
  end

  describe "mix mishka.ui.css.config --regenerate" do
    test "regenerates CSS with user config" do
      # Create user config in test project
      config_content = """
      import Config
      config :mishka_chelekom,
        css_overrides: %{
          primary_light: "#ff0000"
        }
      """
      
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", config_content)
        |> Igniter.compose_task(Config, ["--regenerate"])
      
      # Should create vendor CSS
      assert_creates(igniter, "assets/vendor/mishka_chelekom.css")
      
      # Check the content
      source = igniter.rewrite.sources["assets/vendor/mishka_chelekom.css"]
      content = Rewrite.Source.get(source, :content)
      assert String.contains?(content, "#ff0000")
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "regenerated")
    end
  end

  describe "mix mishka.ui.css.config --validate" do
    test "validates valid config" do
      # Create valid config in test project
      config_content = """
      import Config
      config :mishka_chelekom,
        css_overrides: %{
          primary_light: "#007f8c"
        },
        css_merge_strategy: :merge
      """
      
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", config_content)
        |> Igniter.compose_task(Config, ["--validate"])
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "valid")
      
      # Should not have issues
      assert igniter.issues == []
    end

    test "reports invalid merge strategy" do
      # Create invalid config in test project
      config_content = """
      import Config
      config :mishka_chelekom,
        css_merge_strategy: :invalid
      """
      
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", config_content)
        |> Igniter.compose_task(Config, ["--validate"])
      
      # Check issues
      issues_text = Enum.join(igniter.issues, " ")
      assert String.contains?(issues_text, "Invalid css_merge_strategy")
    end
  end

  describe "mix mishka.ui.css.config --show" do
    test "shows configuration" do
      # Create config in test project
      config_content = """
      import Config
      config :mishka_chelekom,
        css_overrides: %{
          primary_light: "#custom"
        }
      """
      
      igniter = 
        test_project()
        |> Igniter.create_new_file("priv/mishka_chelekom/config.exs", config_content)
        |> Igniter.compose_task(Config, ["--show"])
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "Current Mishka CSS Configuration")
      assert String.contains?(notices_text, "primary_light")
    end

    test "shows default when no config" do
      igniter = 
        test_project()
        |> Igniter.compose_task(Config, ["--show"])
      
      # Check notices
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "Current Mishka CSS Configuration")
      assert String.contains?(notices_text, "(not created)")
    end
  end

  describe "option aliases" do
    test "supports -i for --init" do
      igniter = 
        test_project()
        |> Igniter.compose_task(Config, ["-i"])
      
      assert_creates(igniter, "priv/mishka_chelekom/config.exs")
    end
  end

  describe "help message" do
    test "shows help when no options provided" do
      igniter = 
        test_project()
        |> Igniter.compose_task(Config, [])
      
      notices_text = Enum.join(igniter.notices, " ")
      assert String.contains?(notices_text, "Please specify an action")
      assert String.contains?(notices_text, "--init")
      assert String.contains?(notices_text, "--regenerate")
    end
  end
end