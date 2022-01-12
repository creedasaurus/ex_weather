import Config

config :logger, :console, format: "$time $metadata[$level] $levelpad$message\n"
config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{config_env()}.exs"
