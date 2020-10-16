defmodule PrometheusParser.Line do
  defstruct line_type: nil,
            timestamp: nil,
            pairs: [],
            value: nil,
            documentation: nil,
            type: nil,
            label: nil
end

defimpl String.Chars, for: PrometheusParser.Line do
  def pairs_to_string(pairs) do
    pairs
    |> Enum.map(fn {key, value} -> "#{key}=\"#{value}\"" end)
    |> Enum.join(", ")
  end

  def to_string(%{line_type: "COMMENT", documentation: documentation}),
    do: "# #{documentation}"

  def to_string(%{line_type: "HELP", label: label, documentation: documentation}),
    do: "# HELP #{label} #{documentation}"

  def to_string(%{line_type: "TYPE", label: label, type: type}),
    do: "# TYPE #{label} #{type}"

  def to_string(%{
        line_type: "ENTRY",
        label: label,
        pairs: pairs,
        value: value,
        timestamp: timestamp
      })
      when not is_nil(timestamp) do
    "#{label}{#{pairs_to_string(pairs)}} #{value} #{timestamp}"
  end

  def to_string(%{
        line_type: "ENTRY",
        label: label,
        pairs: pairs,
        value: value
      }) do
    "#{label}{#{pairs_to_string(pairs)}} #{value}"
  end
end

defmodule PrometheusParser do
  import NimbleParsec
  alias PrometheusParser.Line

  comment =
    string("#")
    |> tag(:comment)
    |> ignore(string(" "))

  documentation =
    utf8_string([], min: 1)
    |> tag(:documentation)

  prom_label = ascii_string([?a..?z] ++ [?_], min: 2)

  help =
    string("HELP")
    |> tag(:help)
    |> ignore(string(" "))
    |> concat(prom_label)
    |> tag(:prom_label)
    |> ignore(string(" "))
    |> concat(documentation)

  type =
    string("TYPE")
    |> tag(:type)
    |> ignore(string(" "))
    |> concat(prom_label)
    |> ignore(string(" "))
    |> choice([
      string("gauge"),
      string("counter")
    ])
    |> tag(:type)

  prom_key_value =
    prom_label
    |> tag(:pair_key)
    |> ignore(string("=\""))
    |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-..?-, ?_..?_], min: 2)
    |> label("expected a-z,A-Z,0-9,\-")
    |> tag(:pair_value)
    |> ignore(string("\""))

  prom_integer = ascii_string([?0..?9], min: 1)

  prom_entry =
    prom_label
    |> tag(:prom_label)
    |> ignore(string("{"))
    |> repeat(
      prom_key_value
      |> ignore(optional(string(",")))
      |> ignore(optional(string(" ")))
    )
    |> ignore(string("}"))
    |> ignore(string(" "))
    |> concat(prom_integer |> tag(:entry_value))

  prom_entry_with_timestamp =
    prom_entry
    |> ignore(string(" "))
    |> concat(prom_integer |> tag(:timestamp))

  defparsec(
    :parse_line,
    choice([
      comment |> concat(help),
      comment |> concat(type),
      comment |> concat(documentation),
      prom_entry_with_timestamp,
      prom_entry
    ])
  )

  def parse_file(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse/1)
  end

  def parse(line) do
    line
    |> parse_line()
    |> format()
  end

  def format({:ok, acc, "" = _rest, %{} = _context, _line, _offset}),
    do: format(acc)

  def format(acc) when is_list(acc) do
    acc
    |> Enum.reduce(%Line{}, fn item, acc ->
      case item do
        {:comment, ["#"]} ->
          %{acc | line_type: "COMMENT"}

        {:prom_label, [{:help, ["HELP"]}, label]} ->
          %{acc | line_type: "HELP", label: label}

        {:prom_label, [label]} ->
          %{acc | line_type: "ENTRY", label: label}

        {:type, [{:type, ["TYPE"]}, label, type]} ->
          %{acc | line_type: "TYPE", label: label, type: type}

        {:documentation, [documentation]} ->
          %{acc | documentation: documentation}

        {:pair_value, [{:pair_key, [key]}, value]} ->
          %{acc | pairs: acc.pairs ++ [{key, value}]}

        {:entry_value, [value]} ->
          %{acc | value: value}

        {:timestamp, [timestamp]} ->
          %{acc | timestamp: timestamp}
      end
    end)
  end
end
