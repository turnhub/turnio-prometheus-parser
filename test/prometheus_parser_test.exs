defmodule PrometheusParserTest do
  use ExUnit.Case
  import PrometheusParser

  test "parse garbage" do
    assert parse("blurp") == {:error, "Unsupported syntax: \"blurp\""}
  end

  test "parse comment" do
    assert parse("# Some documenting text") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: "Some documenting text",
                line_type: "COMMENT"
              }}
  end

  test "write comment" do
    assert to_string(%PrometheusParser.Line{
             documentation: "Some documenting text",
             line_type: "COMMENT"
           }) == "# Some documenting text"
  end

  test "parse help" do
    assert parse("# HELP web_uptime Number of seconds since web server has started") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: "Number of seconds since web server has started",
                label: "web_uptime",
                line_type: "HELP"
              }}
  end

  test "write help" do
    assert to_string(%PrometheusParser.Line{
             documentation: "Number of seconds since web server has started",
             label: "web_uptime",
             line_type: "HELP"
           }) == "# HELP web_uptime Number of seconds since web server has started"
  end

  test "parse type" do
    assert parse("# TYPE web_uptime gauge") ==
             {:ok, %PrometheusParser.Line{label: "web_uptime", line_type: "TYPE", type: "gauge"}}
  end

  test "write type" do
    assert to_string(%PrometheusParser.Line{label: "web_uptime", line_type: "TYPE", type: "gauge"}) ==
             "# TYPE web_uptime gauge"
  end

  test "parse entry without key and value" do
    assert parse("pending_messages 0") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "pending_messages",
                line_type: "ENTRY",
                pairs: [],
                timestamp: nil,
                type: nil,
                value: "0"
              }}
  end

  test "write entry without key and value" do
    assert to_string(%PrometheusParser.Line{
             documentation: nil,
             label: "pending_messages",
             line_type: "ENTRY",
             pairs: [],
             timestamp: nil,
             type: nil,
             value: "0"
           }) == "pending_messages 0"
  end

  test "parse entry with key and value" do
    assert parse("web_connections{node=\"abc-123-def-0\"} 607180") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "web_connections",
                line_type: "ENTRY",
                pairs: [{"node", "abc-123-def-0"}],
                timestamp: nil,
                type: nil,
                value: "607180"
              }}
  end

  test "empty attributes" do
    assert parse("out_message_sent_duration_ms_count{retry=\"0\",type=\"\"} 2") ==
             {:ok,
              %PrometheusParser.Line{
                label: "out_message_sent_duration_ms_count",
                line_type: "ENTRY",
                pairs: [{"retry", "0"}, {"type", ""}],
                timestamp: nil,
                type: nil,
                value: "2"
              }}
  end

  test "multiple attributes without spaces" do
    assert parse("out_message_sent_duration_ms_count{retry=\"0\",type=\"undefined\"} 2") ==
             {:ok,
              %PrometheusParser.Line{
                label: "out_message_sent_duration_ms_count",
                line_type: "ENTRY",
                pairs: [{"retry", "0"}, {"type", "undefined"}],
                timestamp: nil,
                type: nil,
                value: "2"
              }}
  end

  test "parse entry with key and value with colons and full stops" do
    assert parse("api_requests_coreapp_duration_ms_sum{app=\"127.0.0.1:6250\"} 122") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "api_requests_coreapp_duration_ms_sum",
                line_type: "ENTRY",
                pairs: [{"app", "127.0.0.1:6250"}],
                timestamp: nil,
                type: nil,
                value: "122"
              }}
  end

  test "write entry with key and value" do
    assert to_string(%PrometheusParser.Line{
             documentation: nil,
             label: "web_connections",
             line_type: "ENTRY",
             pairs: [{"node", "abc-123-def-0"}],
             timestamp: nil,
             type: nil,
             value: "607180"
           }) ==
             "web_connections{node=\"abc-123-def-0\"} 607180"
  end

  test "parse entry with multiple keys and value" do
    assert parse("web_connections{node=\"abc-123-def-0\", bar=\"baz\"} 607180") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "web_connections",
                line_type: "ENTRY",
                pairs: [{"node", "abc-123-def-0"}, {"bar", "baz"}],
                timestamp: nil,
                type: nil,
                value: "607180"
              }}
  end

  test "parse entry with float value" do
    assert parse(
             ~s(pg_stat_statements_total_queries{supabase_project_ref="ixlqpcigbdlbmfnvzxtw",service_type="postgresql",server="localhost:5432"} 4.37379e+06)
           ) ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "pg_stat_statements_total_queries",
                line_type: "ENTRY",
                pairs: [
                  {"supabase_project_ref", "ixlqpcigbdlbmfnvzxtw"},
                  {"service_type", "postgresql"},
                  {"server", "localhost:5432"}
                ],
                timestamp: nil,
                type: nil,
                value: "4.37379e+06"
              }}
  end

  test "parse entry with float value and capital E" do
    assert parse(
             ~s(pg_stat_statements_total_queries{supabase_project_ref="ixlqpcigbdlbmfnvzxtw",service_type="postgresql",server="localhost:5432"} 4.37379E+06)
           ) ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "pg_stat_statements_total_queries",
                line_type: "ENTRY",
                pairs: [
                  {"supabase_project_ref", "ixlqpcigbdlbmfnvzxtw"},
                  {"service_type", "postgresql"},
                  {"server", "localhost:5432"}
                ],
                timestamp: nil,
                type: nil,
                value: "4.37379E+06"
              }}
  end

  test "parse entry with uppercase prom_label" do
    assert parse(
             ~s(node_memory_KReclaimable_bytes{supabase_project_ref="ixlqpcigbdlbmfnvzxtw",service_type="db"} 8.8190976e+07)
           ) ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "node_memory_KReclaimable_bytes",
                line_type: "ENTRY",
                pairs: [
                  {"supabase_project_ref", "ixlqpcigbdlbmfnvzxtw"},
                  {"service_type", "db"}
                ],
                timestamp: nil,
                type: nil,
                value: "8.8190976e+07"
              }}
  end

  test "write entry with multiple keys and values" do
    assert to_string(%PrometheusParser.Line{
             documentation: nil,
             label: "web_connections",
             line_type: "ENTRY",
             pairs: [{"node", "abc-123-def-0"}, {"bar", "baz"}],
             timestamp: "1234",
             type: nil,
             value: "607180"
           }) ==
             "web_connections{node=\"abc-123-def-0\", bar=\"baz\"} 607180 1234"
  end

  test "parse entry with timestamp" do
    assert parse("web_connections{node=\"abc-123-def-0\"} 607180 200") ==
             {:ok,
              %PrometheusParser.Line{
                documentation: nil,
                label: "web_connections",
                line_type: "ENTRY",
                pairs: [{"node", "abc-123-def-0"}],
                timestamp: "200",
                type: nil,
                value: "607180"
              }}
  end

  test "write entry with timestamp" do
    assert to_string(%PrometheusParser.Line{
             documentation: nil,
             label: "web_connections",
             line_type: "ENTRY",
             pairs: [{"node", "abc-123-def-0"}],
             timestamp: "1234",
             type: nil,
             value: "607180"
           }) ==
             "web_connections{node=\"abc-123-def-0\"} 607180 1234"
  end
end
