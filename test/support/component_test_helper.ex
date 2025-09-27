defmodule MishkaChelekom.ComponentTestHelper do
  @moduledoc """
  Helper functions for component generation tests
  """

  @config_path "config/config.exs"
  @config_backup_path "config/config.exs.backup"

  @doc """
  Creates a test project with .formatter.exs included
  """
  def test_project_with_formatter(opts \\ []) do
    files = Keyword.get(opts, :files, %{})

    files_with_formatter = Map.put_new(files, ".formatter.exs", """
    [inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"]]
    """)

    opts_with_formatter = Keyword.put(opts, :files, files_with_formatter)
    Igniter.Test.test_project(opts_with_formatter)
  end

  def setup_config do
    # Backup existing config if it exists
    if File.exists?(@config_path) do
      File.rename!(@config_path, @config_backup_path)
    end

    # Ensure config directory exists
    File.mkdir_p!("config")

    # Create a test config file
    File.write!(@config_path, """
    import Config

    config :tailwind, version: "4.0.0"

    config :test_project, TestProjectWeb.Endpoint,
      url: [host: "localhost"],
      secret_key_base: "test"
    """)
  end

  def cleanup_config do
    # Remove test config
    if File.exists?(@config_path) do
      File.rm!(@config_path)
    end

    # Restore backup if it exists
    if File.exists?(@config_backup_path) do
      File.rename!(@config_backup_path, @config_path)
    end
  end

  def with_config(fun) do
    setup_config()

    try do
      fun.()
    after
      cleanup_config()
    end
  end
end
