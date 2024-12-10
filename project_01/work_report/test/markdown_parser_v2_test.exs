defmodule MarkdownParserV2Test do
  use ExUnit.Case

  alias WorkReport.MarkdownParserV2, as: MarkdownParser
  alias WorkReport.Model.{Day, Month, Task}

  import CommonTestFixtures
  import MarkdownParserTestFixtures

  describe "parse_report" do
    test "should parse single month report" do
      report = Path.expand("test/sample/single-report-1.md") |> File.read!()

      assert MarkdownParser.parse_report(report) ==
               {:ok, [single_month_fixture()]}
    end

    test "should parse plural month report" do
      report = Path.expand("test/sample/plural-report.md") |> File.read!()

      assert MarkdownParser.parse_report(report) ==
               {:ok, plural_month_fixture()}
    end

    test "should parse plural month report without empty lines" do
      report = Path.expand("test/sample/plural-report-no-empty-lines.md") |> File.read!()

      assert MarkdownParser.parse_report(report) ==
               {:ok, plural_month_fixture()}
    end
  end

  describe "build_entity_list" do
    test "should build month model tree with days" do
      assert MarkdownParser.build_entity_list([
               month_fixture(variant: 1),
               day_fixture(variant: 1),
               day_fixture(variant: 2),
               month_fixture(variant: 2),
               day_fixture(variant: 3),
               day_fixture(variant: 4)
             ]) == [
               Map.put(month_fixture(variant: 1), :days, [
                 day_fixture(variant: 1),
                 day_fixture(variant: 2)
               ]),
               Map.put(month_fixture(variant: 2), :days, [
                 day_fixture(variant: 3),
                 day_fixture(variant: 4)
               ])
             ]
    end

    test "should build month model tree with days and tasks" do
      assert MarkdownParser.build_entity_list([
               month_fixture(variant: 1),
               day_fixture(variant: 1),
               task_fixture(variant: 1),
               task_fixture(variant: 2),
               day_fixture(variant: 2),
               task_fixture(variant: 3),
               task_fixture(variant: 4),
               month_fixture(variant: 2),
               day_fixture(variant: 3),
               task_fixture(variant: 5),
               task_fixture(variant: 6),
               day_fixture(variant: 4),
               task_fixture(variant: 7),
               task_fixture(variant: 8)
             ]) == plural_month_fixture()
    end

    test "should return error element for unknown entity" do
      assert MarkdownParser.build_entity_list([
               month_fixture(variant: 1),
               day_fixture(variant: 1),
               day_fixture(variant: 2),
               "something not match"
             ]) == [
               Map.put(month_fixture(variant: 1), :days, [
                 day_fixture(variant: 1),
                 day_fixture(variant: 2)
               ]),
               {:error, "unprocessible_entity"}
             ]
    end
  end

  describe "map_entity_string" do
    test "should match month string" do
      assert MarkdownParser.map_entity_string("# June") == %Month{
               days: [],
               number: 6,
               title: "June"
             }
    end

    test "should match day string" do
      assert MarkdownParser.map_entity_string("## 5 tue") == %Day{
               number: 5,
               title: "tue",
               tasks: []
             }
    end

    test "should match task string" do
      assert MarkdownParser.map_entity_string("[DEV] Review Pull Requests - 27m") == %Task{
               category: "DEV",
               description: "Review Pull Requests",
               time_spent: 27
             }
    end

    test "should return an error for invalid entity format" do
      invalid_entities = [
        "### June",
        "#June",
        "January",
        "[DEV]Review Pull Requests-27m",
        "[DEV] Review Pull Requests - 27 minutes",
        "## tue 5",
        "##6fri"
      ]

      for entity <- invalid_entities do
        assert MarkdownParser.map_entity_string(entity) ==
                 {:error, "wrong_entity_format", context: entity}
      end
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

    test "should return an error for invalid time string" do
      invalid_time = "some"

      assert MarkdownParser.parse_time(invalid_time) ==
               {:error, "wrong_time_string_format", context: "some"}
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

    test "should return an error for not string argument" do
      invalid_string = 42

      assert MarkdownParser.string_to_int(invalid_string) ==
               {:error, "not_binary_argument", context: invalid_string}
    end

    test "should return an error for not convertable string" do
      invalid_string = "some"

      assert MarkdownParser.string_to_int(invalid_string) ==
               {:error, "string_is_not_convertable_to_integer", context: invalid_string}
    end
  end
end
