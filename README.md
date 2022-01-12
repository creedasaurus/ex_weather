# ExWeather

Get me the weather (with Elixir)! You'll want to find some cities on https://www.findmecity.com/ to get a WOEID or "Where on Earth IDentifier". That's
the input for the CLI itself.

### Building and Running

This is a basic `Mix` project. This is a CLI, so I'm building as an `escript`.

Fetch the dependencies:

```
mix deps.get
```

Build with whatever environment (dev, prod, test)

```
MIX_ENV=prod mix escript.build
```

And run the script, or move it into your path:

```
./_build/ex_weather
```

_\*note: I'll go ahead and just vendor the compiled binary in the root directory, but feel free to build it again_

### Example commands

Here are some basic commands you can run to get started:

Fetch the max average temperature of 7 days for SLC, LA, NYC, and Boise. Also set the concurrency to 2 and enable verbose logging. This
will let slow the process a little and let you inspect the behavior:

```
╰─❯ ex_weather --verbose --concurrency 2 --days 7 2487610 2442047 2459115 2366355
```

Print out a help prompt of options:

```bash
╰─❯ ex_weather --help
ex_weather is a toy project to test out some Elixir.

USAGE:
  ex_weather [OPTIONS] INPUT
OPTIONS:
  -h, --help
  -v, --verbose     Set the log output to debug level
  -c, --concurrency Set the maximum concurrency for the http calls
                      (default: 5)
  -d, --days        Number of days to average the max_temp
                      (default: 6, max: 10) -- after so many days, there isnt much data
INPUT:
  <locations>...    The location(s) ID or "woeid" (Where on earth identifier)
                      see: https://www.findmecity.com/

Example:
  Get the average max_temp for SLC, LA, and NYC
  $ ex_weather 2487610 2442047 2459115

  Get the average max_temp for LA over 3 days
  $ ex_weather --days 3 2442047

```
