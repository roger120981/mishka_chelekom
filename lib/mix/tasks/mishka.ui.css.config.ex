defmodule Mix.Tasks.Mishka.Ui.Css.Config do
  use Igniter.Mix.Task
  alias MishkaChelekom.CSSConfig

  @example "mix mishka.ui.css.config --init"
  @shortdoc "Manages CSS configuration for Mishka Chelekom components"
  @moduledoc """
  #{@shortdoc}

  This task helps you manage CSS customization for Mishka components.
  You can create a configuration file, validate it, or regenerate CSS with your overrides.

  ## Examples

  Initialize a configuration file:
  ```bash
  mix mishka.ui.css.config --init
  ```

  Force overwrite existing configuration with sample:
  ```bash
  mix mishka.ui.css.config --init --force
  ```

  Regenerate CSS with current configuration:
  ```bash
  mix mishka.ui.css.config --regenerate
  ```

  Validate your configuration:
  ```bash
  mix mishka.ui.css.config --validate
  ```

  ## Options

  * `--init` - Creates a sample configuration file
  * `--force` - Force overwrite existing configuration file (use with --init)
  * `--regenerate` - Regenerates CSS files with current configuration
  * `--validate` - Validates the current configuration
  * `--show` - Shows the current configuration
  """

  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      adds_deps: [],
      installs: [],
      example: @example,
      extra_args?: false,
      only: nil,
      positional: [],
      composes: [],
      schema: [
        init: :boolean,
        force: :boolean,
        regenerate: :boolean,
        validate: :boolean,
        show: :boolean
      ],
      aliases: [
        i: :init,
        f: :force,
        r: :regenerate,
        v: :validate,
        s: :show
      ]
    }
  end

  def igniter(igniter) do
    options = igniter.args.options

    cond do
      options[:init] ->
        init_config(igniter)

      options[:regenerate] ->
        regenerate_css(igniter)

      options[:validate] ->
        validate_config(igniter)

      options[:show] ->
        show_config(igniter)

      true ->
        igniter
        |> Igniter.add_notice("""
        Please specify an action:

        --init       Create a sample configuration file
        --init --force  Force overwrite existing configuration
        --regenerate Regenerate CSS with your configuration
        --validate   Validate your configuration
        --show       Display current configuration

        Example: mix mishka.ui.css.config --init
        """)
    end
  end

  defp init_config(igniter) do
    {igniter, config_path, content} = CSSConfig.create_sample_config(igniter)
    options = igniter.args.options
    force = Keyword.get(options, :force, false)

    # Check if file already exists in the igniter's sources
    existing_source = igniter.rewrite.sources[config_path]
    file_exists = existing_source != nil || File.exists?(config_path)

    cond do
      file_exists && !force ->
        igniter
        |> Igniter.add_notice("""
        Configuration file already exists at:
        #{config_path}

        You can edit this file to customize CSS variables.
        To overwrite with a fresh sample, use: mix mishka.ui.css.config --init --force
        """)

      file_exists && force ->
        igniter
        |> Igniter.create_or_update_file(config_path, content, fn source ->
          Rewrite.Source.update(source, :content, content)
        end)
        |> Igniter.add_notice("""
        Configuration file overwritten at:
        #{config_path}

        Previous configuration has been replaced.
        You can now customize CSS variables by editing this file.
        Run `mix mishka.ui.css.config --regenerate` after making changes.
        """)

      true ->
        igniter
        |> Igniter.create_or_update_file(config_path, content, fn source ->
          Rewrite.Source.update(source, :content, content)
        end)
        |> Igniter.add_notice("""
        Created configuration file at:
        #{config_path}

        You can now customize CSS variables by editing this file.
        Run `mix mishka.ui.css.config --regenerate` after making changes.
        """)
    end
  end

  defp regenerate_css(igniter) do
    vendor_css_path = "assets/vendor/mishka_chelekom.css"

    # Generate CSS with user configuration
    css_content = CSSConfig.generate_css_content(igniter)

    igniter
    |> Igniter.create_or_update_file(vendor_css_path, css_content, fn source ->
      Rewrite.Source.update(source, :content, css_content)
    end)
    |> Igniter.add_notice("""
    CSS file regenerated with your configuration.

    Updated file:
    - #{vendor_css_path}

    Your customizations have been applied.
    """)
  end

  defp validate_config(igniter) do
    config = CSSConfig.load_user_config(igniter)
    config_path = Path.join(["priv", "mishka_chelekom", "config.exs"])

    issues = validate_configuration(config)

    if issues == [] do
      igniter
      |> Igniter.add_notice("""
      Configuration is valid! ✓

      Configuration file: #{config_path}
      Strategy: #{config.css_merge_strategy}
      CSS overrides: #{map_size(config.css_overrides)} variables
      #{if config.custom_css_path, do: "Custom CSS: #{config.custom_css_path}", else: ""}
      """)
    else
      igniter
      |> Igniter.add_issue("""
      Configuration validation failed:

      #{Enum.join(issues, "\n")}
      """)
    end
  end

  defp validate_configuration(config) do
    issues = []

    # Validate merge strategy
    issues =
      if config.css_merge_strategy not in [:merge, :replace] do
        [
          "Invalid css_merge_strategy: #{inspect(config.css_merge_strategy)}. Must be :merge or :replace"
          | issues
        ]
      else
        issues
      end

    # Validate custom CSS path if using replace strategy
    issues =
      if config.css_merge_strategy == :replace and is_nil(config.custom_css_path) do
        ["When using :replace strategy, custom_css_path must be provided" | issues]
      else
        issues
      end

    # Validate custom CSS file exists if specified
    issues =
      if config.custom_css_path && !File.exists?(config.custom_css_path) do
        ["Custom CSS file not found: #{config.custom_css_path}" | issues]
      else
        issues
      end

    # Validate override values are strings
    issues =
      config.css_overrides
      |> Enum.reduce(issues, fn {key, value}, acc ->
        if !is_binary(value) do
          ["CSS override '#{key}' must be a string, got: #{inspect(value)}" | acc]
        else
          acc
        end
      end)

    issues
  end

  defp show_config(igniter) do
    config = CSSConfig.load_user_config(igniter)
    config_path = Path.join(["priv", "mishka_chelekom", "config.exs"])

    overrides_display =
      if map_size(config.css_overrides) > 0 do
        config.css_overrides
        |> Enum.map(fn {k, v} -> "    #{k}: #{inspect(v)}" end)
        |> Enum.join("\n")
      else
        "    (none)"
      end

    igniter
    |> Igniter.add_notice("""
    Current Mishka CSS Configuration:

    Configuration file: #{if File.exists?(config_path), do: config_path, else: "(not created)"}

    Strategy: #{config.css_merge_strategy}
    Custom CSS path: #{config.custom_css_path || "(not set)"}

    CSS Variable Overrides:
    #{overrides_display}

    To modify, edit: #{config_path}
    Then run: mix mishka.ui.css.config --regenerate
    """)
  end
end
