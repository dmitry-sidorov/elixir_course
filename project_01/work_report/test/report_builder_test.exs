defmodule ReportBuilderTest do
  use ExUnit.Case

  alias WorkReport.ReportBuilder

  import TestFixtures
  import CommonTestFixtures

  describe "build_report" do
    test "should build single month report" do
      assert ReportBuilder.build_report(single_model_list_fixture_2(), 1, 3) ==
               {:ok, single_model_list_report_fixture_2_m1_d3()}
    end

    test "should build plural month report" do
      model = plural_model_list_fixture_1()

      assert ReportBuilder.build_report(model, 6, 5) ==
               {:ok, plural_model_list_report_fixture_1_m6_d5()}
    end

    test "should raise an error for wrong month number" do
      assert ReportBuilder.build_report(single_model_list_fixture_2(), 2, 3) ==
               {:error, "month 2 not found"}
    end

    test "should raise an error for wrong day number" do
      assert ReportBuilder.build_report(single_model_list_fixture_2(), 1, 22) ==
               {:error, "day 22 not found"}
    end

    test "should raise an error for wrong day and month number" do
      assert ReportBuilder.build_report(single_model_list_fixture_2(), 2, 5) ==
               {:error, "month 2 not found"}
    end
  end

  describe "task_valid?" do
    test "should pass for valid task" do
      for task <- ReportBuilder.task_categories() do
        task = Map.put(task_fixture(variant: 1), :category, task)
        assert ReportBuilder.task_valid?(task) == task
      end
    end

    test "should return error" do
      task = Map.put(task_fixture(variant: 1), :category, "INVALID")

      assert ReportBuilder.task_valid?(task) ==
               {:error,
                context:
                  "Invalid category INVALID. Task category should be from the list: COMM, DEV, OPS, DOC, WS, EDU"}
    end
  end

  describe "validate_tasks" do
    test "should return valid tasks" do
      tasks = [
        task_fixture(variant: 1),
        task_fixture(variant: 2),
        task_fixture(variant: 3),
        task_fixture(variant: 4)
      ]

      assert ReportBuilder.validate_tasks(tasks) == {:ok, tasks}
    end

    test "should return error for invalid tasks" do
      tasks = [
        task_fixture(variant: 1),
        Map.put(task_fixture(variant: 2), :category, "NOT_EXISTS"),
        task_fixture(variant: 3),
        task_fixture(variant: 4)
      ]

      assert ReportBuilder.validate_tasks(tasks) ==
               {:error,
                context:
                  "Invalid category NOT_EXISTS. Task category should be from the list: COMM, DEV, OPS, DOC, WS, EDU"}
    end
  end

  describe "build_month_report" do
    test "should build report for valid input" do
      assert ReportBuilder.build_month_report(month_model_fixture_3()) == month_report_fixture_1()
    end

    test "should return error for invalid month model" do
      assert ReportBuilder.build_month_report(month_model_fixture_3(valid_task_category?: false)) ==
               {:error,
                context:
                  "Invalid category SOME. Task category should be from the list: COMM, DEV, OPS, DOC, WS, EDU"}
    end
  end
end
