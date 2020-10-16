use Mix.Config

config :logger, level: :info

config :upload,
  log: false,
  ecto_repos: [Upload.Test.Repo],
  analyzers: [Upload.Analyzer.Image, Upload.Analyzer.Video]

config :upload, Upload.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "upload_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/"

config :upload, Upload.Storage,
  adapter: FileStore.Adapters.Memory,
  base_url: "http://example.com"
