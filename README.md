# PrometheusParser

A simple parser for the Prometheus text format built with [`nimble_parsec`](https://hex.pm/packages/nimble_parsec).
Likely incomplete but works well enough for our use case.

````elixir
iex(1)> PrometheusParser.parse("# Some documenting text")
%PrometheusParser.Line{
               documentation: "Some documenting text",
               line_type: "COMMENT"
             }

iex(1)> PrometheusParser.parse("# HELP web_uptime Number of seconds since web server has started") ==
%PrometheusParser.Line{
  documentation: "Number of seconds since web server has started",
  label: "web_uptime",
  line_type: "HELP"
}

iex(1)> PrometheusParser.parse("# TYPE web_uptime gauge") ==
%PrometheusParser.Line{label: "web_uptime", line_type: "TYPE", type: "gauge"}

iex(1)> PrometheusParser.parse("web_connections{node=\"abc-123-def-0\"} 607180") ==
%PrometheusParser.Line{
  documentation: nil,
  label: "web_connections",
  line_type: "ENTRY",
  pairs: [{"node", "abc-123-def-0"}],
  timestamp: nil,
  type: nil,
  value: "607180"
}
```

Rebuild them into Prometheus output again with `to_string()`:

```elixir
%PrometheusParser.Line{
  documentation: nil,
  label: "web_connections",
  line_type: "ENTRY",
  pairs: [{"node", "abc-123-def-0"}],
  timestamp: nil,
  type: nil,
  value: "607180"
}
iex(3)> to_string(line)
"web_connections{node=\"abc-123-def-0\"} 607180"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `prometheus_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prometheus_parser, "~> 0.1.0"}
  ]
end
````

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/prometheus_parser](https://hexdocs.pm/prometheus_parser).
