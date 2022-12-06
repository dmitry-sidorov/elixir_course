defmodule WorkReportTest do
  use ExUnit.Case

  alias WorkReport.Parser
  alias WorkReport.Formatter

  test "parse time" do
    assert Parser.parse_time("1m") == 1
    assert Parser.parse_time("5m") == 5
    assert Parser.parse_time("12m") == 12
    assert Parser.parse_time("42m") == 42
    assert Parser.parse_time("59m") == 59
    assert Parser.parse_time("60m") == 60
    assert Parser.parse_time("61m") == 61
    assert Parser.parse_time("1h") == 60
    assert Parser.parse_time("1h 5m") == 65
    assert Parser.parse_time("1h 30m") == 90
    assert Parser.parse_time("2h 20m") == 140
    assert Parser.parse_time("1h 90m") == 150
    assert Parser.parse_time("3h") == 180
    assert Parser.parse_time("10h") == 600
    assert Parser.parse_time("10h 15m") == 615

    assert Parser.parse_time("") == 0
    assert Parser.parse_time("0m") == 0
    assert Parser.parse_time("0h") == 0
    assert Parser.parse_time("0m 0h") == 0
    assert Parser.parse_time("whatever") == 0
  end

  test "format time" do
    assert Formatter.format_time(0) == "0"
    assert Formatter.format_time(1) == "1m"
    assert Formatter.format_time(12) == "12m"
    assert Formatter.format_time(42) == "42m"
    assert Formatter.format_time(59) == "59m"
    assert Formatter.format_time(60) == "1h"
    assert Formatter.format_time(61) == "1h 1m"
    assert Formatter.format_time(65) == "1h 5m"
    assert Formatter.format_time(90) == "1h 30m"
    assert Formatter.format_time(140) == "2h 20m"
    assert Formatter.format_time(150) == "2h 30m"
    assert Formatter.format_time(180) == "3h"
    assert Formatter.format_time(600) == "10h"
    assert Formatter.format_time(615) == "10h 15m"
  end

  test "prepare file content" do
    str = """
    # March

    ## 09 tue
    [DEV] TASK-15 implement feature - 42m
    [COMM] Daily Meeting - 24m
    [DEV] TASK-15 implement - 25m

    ## 10 wed
    [DEV] Review Pull Requests - 17m
    [COMM] Sprint Planning - 1h
    # April

    ## 15 thu
    [COMM] Daily Meeting - 19m

    ## 16 fri
    [DEV] TASK-20 implementation - 17m
    [COMM] Daily Meeting - 22m
    [DEV] TASK-19 investigate bug - 43m
    """

    result = [
      "# March",
      "## 09 tue",
      "[DEV] TASK-15 implement feature - 42m",
      "[COMM] Daily Meeting - 24m",
      "[DEV] TASK-15 implement - 25m",
      "## 10 wed",
      "[DEV] Review Pull Requests - 17m",
      "[COMM] Sprint Planning - 1h",
      "# April",
      "## 15 thu",
      "[COMM] Daily Meeting - 19m",
      "## 16 fri",
      "[DEV] TASK-20 implementation - 17m",
      "[COMM] Daily Meeting - 22m",
      "[DEV] TASK-19 investigate bug - 43m"
    ]

    assert Parser.prepare_file_content(str) == result
  end

  test "group by marker" do
    data = [
      "## 09 tue",
      "[DEV] TASK-15 implement feature - 42m",
      "[COMM] Daily Meeting - 24m",
      "[DEV] TASK-15 implement - 25m",
      "## 10 wed",
      "[DEV] Review Pull Requests - 17m",
      "[COMM] Sprint Planning - 1h",
      "## 15 thu",
      "[COMM] Daily Meeting - 19m",
      "## 16 fri",
      "[DEV] TASK-20 implementation - 17m",
      "[COMM] Daily Meeting - 22m",
      "[DEV] TASK-19 investigate bug - 43m"
    ]

    result = [
      %{
        header: "## 09 tue",
        items: [
          "[DEV] TASK-15 implement feature - 42m",
          "[COMM] Daily Meeting - 24m",
          "[DEV] TASK-15 implement - 25m"
        ]
      },
      %{
        header: "## 10 wed",
        items: [
          "[DEV] Review Pull Requests - 17m",
          "[COMM] Sprint Planning - 1h"
        ]
      },
      %{
        header: "## 15 thu",
        items: [
          "[COMM] Daily Meeting - 19m"
        ]
      },
      %{
        header: "## 16 fri",
        items: [
          "[DEV] TASK-20 implementation - 17m",
          "[COMM] Daily Meeting - 22m",
          "[DEV] TASK-19 investigate bug - 43m"
        ]
      }
    ]

    assert Parser.group_by_marker(data, "## ") == result
  end

  test "split to months and days" do
    data = [
      "# March",
      "## 09 tue",
      "[DEV] TASK-15 implement feature - 42m",
      "[COMM] Daily Meeting - 24m",
      "[DEV] TASK-15 implement - 25m",
      "## 10 wed",
      "[DEV] Review Pull Requests - 17m",
      "[COMM] Sprint Planning - 1h",
      "# April",
      "## 15 thu",
      "[COMM] Daily Meeting - 19m",
      "## 16 fri",
      "[DEV] TASK-20 implementation - 17m",
      "[COMM] Daily Meeting - 22m",
      "[DEV] TASK-19 investigate bug - 43m"
    ]

    result = [
      %{
        header: "# March",
        items: [
          %{
            header: "## 09 tue",
            items: [
              "[DEV] TASK-15 implement feature - 42m",
              "[COMM] Daily Meeting - 24m",
              "[DEV] TASK-15 implement - 25m"
            ]
          },
          %{
            header: "## 10 wed",
            items: [
              "[DEV] Review Pull Requests - 17m",
              "[COMM] Sprint Planning - 1h"
            ]
          }
        ]
      },
      %{
        header: "# April",
        items: [
          %{
            header: "## 15 thu",
            items: [
              "[COMM] Daily Meeting - 19m"
            ]
          },
          %{
            header: "## 16 fri",
            items: [
              "[DEV] TASK-20 implementation - 17m",
              "[COMM] Daily Meeting - 22m",
              "[DEV] TASK-19 investigate bug - 43m"
            ]
          }
        ]
      }
    ]

    assert Parser.split_to_months_and_days(data) == result
  end

  alias WorkReport.Model.Task

  test "parse task" do
    data = "[DEV] TASK-20 implementation - 17m"
    result = %Task{category: "DEV", description: "TASK-20 implementation", time: 17}
    assert Parser.parse_task(data) == result
  end

  test "map to model" do
    data = [
      %{
        header: "# March",
        items: [
          %{
            header: "## 10 wed",
            items: [
              "[DEV] Review Pull Requests - 17m",
              "[COMM] Sprint Planning - 1h"
            ]
          }
        ]
      },
      %{
        header: "# April",
        items: [
          %{
            header: "## 15 thu",
            items: [
              "[COMM] Daily Meeting - 19m"
            ]
          },
          %{
            header: "## 16 fri",
            items: [
              "[COMM] Daily Meeting - 22m",
              "[DEV] TASK-19 investigate bug - 43m"
            ]
          }
        ]
      }
    ]

    result = [
      %{
        header: "# March",
        items: [
          %{
            header: "## 10 wed",
            items: [
              %Task{category: "DEV", description: "Review Pull Requests", time: 17},
              %Task{category: "COMM", description: "Sprint Planning", time: 60}
            ]
          }
        ]
      },
      %{
        header: "# April",
        items: [
          %{
            header: "## 15 thu",
            items: [
              %Task{category: "COMM", description: "Daily Meeting", time: 19}
            ]
          },
          %{
            header: "## 16 fri",
            items: [
              %Task{category: "COMM", description: "Daily Meeting", time: 22},
              %Task{category: "DEV", description: "TASK-19 investigate bug", time: 43}
            ]
          }
        ]
      }
    ]

    assert Parser.map_to_model(data) == result
  end
end