defmodule FormatterTest do
  use ExUnit.Case
  import TestFixtures

  alias WorkReport.{Formatter, TerminalFormatter}

  defp expected_report do
    "Day: 3 mon\n - DEV: Implement search - 4h\n - COMM: Daily Meeting with indians - 20m\n - DEV: Implement endoint for auth - 1h 40m\n - DOC: Read API docs and manuals - 1h\n   Total: 7h\n\nMonth: January\n - COMM: 35m\n - DEV: 8h 30m\n - OPS: 0\n - DOC: 1h\n - WS: 0\n - EDU: 0\n   Total: 10h 5m, Days: 2, Avg: 5h 2m\n"
  end

  describe "formatter interface" do
    test "print_report should print correct report" do
      assert Formatter.print_report(single_model_list_report_fixture_2_m1_d3(),
               formatter: TerminalFormatter
             ) == {:ok, expected_report()}
    end
  end
end
