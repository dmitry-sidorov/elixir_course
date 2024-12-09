defmodule MarkdownParserV2Test do
  use ExUnit.Case

  alias WorkReport.MarkdownParserV2, as: MarkdownParser
  alias WorkReport.Model.{Day, Month, Task}

  import TestFixtures

  describe "parse_report" do
    test "should parse single month report" do
      report = Path.expand("test/sample/single-report-1.md") |> File.read!()

      assert MarkdownParser.parse_report(report) ==
               {:ok, single_model_list_fixture_1()}
    end

    test "should parse plural month report" do
      report = Path.expand("test/sample/plural-report.md") |> File.read!()

      assert MarkdownParser.parse_report(report) ==
               {:ok, TestFixtures.plural_model_list_fixture_1()}
    end
  end

  describe "check_string" do
    test "should match month string" do
      assert MarkdownParser.map_entity_string("# June") == %{"month_title" => "June"}
    end

    test "should match day string" do
      assert MarkdownParser.map_entity_string("## 5 tue") == %{
               "day_title" => "tue",
               "number" => "5"
             }
    end

    test "should match task string" do
      assert MarkdownParser.map_entity_string("[DEV] Review Pull Requests - 27m") == %{
               "category" => "DEV",
               "description" => "Review Pull Requests",
               "time_spent" => "27m"
             }
    end
  end

  describe "parse_month_string" do
    test "should parse correct month string" do
      assert MarkdownParser.parse_month_string("# January") == %Month{
               number: 1,
               title: "January",
               days: []
             }

      assert MarkdownParser.parse_month_string("# February") == %Month{
               number: 2,
               title: "February",
               days: []
             }

      assert MarkdownParser.parse_month_string("# March") == %Month{
               number: 3,
               title: "March",
               days: []
             }
    end

    test "should return an error for invalid month string" do
      invalid_month = "## January"

      assert MarkdownParser.parse_month_string(invalid_month) ==
               {:error, "wrong_month_string_format", context: invalid_month}
    end
  end

  describe "parse_task" do
    test "should parse a task" do
      assert MarkdownParser.parse_task("[SOME] Do something useful - 30m") == %Task{
               category: "SOME",
               description: "Do something useful",
               time_spent: 30
             }
    end

    test "should return an error for invalid task" do
      invalid_tasks = ["[SOME] Do something useful - eff", "Some Do something useful - 30r"]

      for task <- invalid_tasks do
        assert MarkdownParser.parse_task(task) ==
                 {:error, "wrong_task_string_format", context: task}
      end
    end
  end

  describe "parse_day_string" do
    test "should parse a day string to map" do
      assert MarkdownParser.parse_day_string("## 3 mon") == %Day{
               number: 3,
               title: "mon",
               tasks: []
             }
    end

    test "should return an error for invalid day string" do
      assert MarkdownParser.parse_day_string("some shit") ==
               {:error, "wrong_day_string_format", context: "some shit"}
    end
  end

  describe "parse_task_list" do
    test "should parse task string list" do
      assert MarkdownParser.parse_task_list(%Day{number: 1, title: "mon"}, [
               "[SOME] Test title - 15m",
               "[DEV] Do some useful stuff - 2h",
               "[COM] Daily meeting with indians - 5h 30m"
             ]) == %Day{
               number: 1,
               title: "mon",
               tasks: [
                 %Task{category: "SOME", description: "Test title", time_spent: 15},
                 %Task{category: "DEV", description: "Do some useful stuff", time_spent: 120},
                 %Task{
                   category: "COM",
                   description: "Daily meeting with indians",
                   time_spent: 330
                 }
               ]
             }
    end
  end

  describe "parse_day" do
    test "should parse valid day string" do
      assert MarkdownParser.parse_day(
               "## 3 mon\n[DEV] Review Shitty Pull Requests - 30m\n[COMM] Daily Meeting with arabs - 15m\n[DEV] Implement cool feature for legacy monster - 4h\n"
             ) == %Day{
               number: 3,
               title: "mon",
               tasks: [
                 %Task{
                   category: "DEV",
                   description: "Review Shitty Pull Requests",
                   time_spent: 30
                 },
                 %Task{category: "COMM", description: "Daily Meeting with arabs", time_spent: 15},
                 %Task{
                   category: "DEV",
                   description: "Implement cool feature for legacy monster",
                   time_spent: 240
                 }
               ]
             }
    end
  end

  describe "parse_time" do
    test "should parse time string" do
      assert MarkdownParser.parse_time("1h 22m") == 82
      assert MarkdownParser.parse_time("2h 2m") == 122
    end

    test "should parse time string minutes only" do
      assert MarkdownParser.parse_time("22m") == 22
      assert MarkdownParser.parse_time("42m") == 42
      assert MarkdownParser.parse_time("1m") == 1
      assert MarkdownParser.parse_time("0m") == 0
    end

    test "should parse time string hours only" do
      assert MarkdownParser.parse_time("1h") == 60
      assert MarkdownParser.parse_time("2h") == 120
      assert MarkdownParser.parse_time("15h") == 900
    end
  end

  describe "string_to_int" do
    test "should convert string to int" do
      assert MarkdownParser.string_to_int("42") == 42
    end

    test "should convert string to int with trailing zero" do
      assert MarkdownParser.string_to_int("02") == 2
    end

    test "should return 0 for an empty string" do
      assert MarkdownParser.string_to_int("") == 0
    end
  end
end
