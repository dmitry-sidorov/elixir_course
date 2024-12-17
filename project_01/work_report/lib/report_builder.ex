defmodule WorkReport.ReportBuilder do
  @moduledoc """
    Module takes models of subject area and returns list of report models.
  """

  alias WorkReport.Model.{CategoryReport, Day, DayReport, Month, MonthReport, Task, Report}

  @type report_builder_error :: {:error, String.t()}

  @task_categories [
    "COMM",
    "DEV",
    "OPS",
    "DOC",
    "WS",
    "EDU"
  ]

  def build_report({:error, _message} = error, _month_number, _day_number), do: error

  @spec build_report(
          month_list :: [Month.t()],
          month_number :: integer(),
          day_number :: integer()
        ) ::
          [Report.t()] | report_builder_error()
  def build_report(month_list, month_number, day_number) do
    report_list =
      case Enum.find(month_list, fn %Month{number: number} -> number == month_number end) do
        nil ->
          [{:error, "month #{inspect(month_number)} not found"}]

        %Month{} = month ->
          [build_day_report(month, day_number), build_month_report(month)]
      end

    case Enum.find(report_list, &error?/1) do
      nil -> {:ok, report_list}
      error -> error
    end
  end

  def error?({:error, _} = element) when is_tuple(element), do: true
  def error?(element) when is_map(element), do: false

  @spec build_day_report(month :: Month.t(), day_number :: integer()) ::
          DayReport.t() | report_builder_error()
  def build_day_report(%Month{days: days}, day_number) do
    case Enum.find(days, fn %Day{number: number} -> number == day_number end) do
      nil ->
        {:error, "day #{inspect(day_number)} not found"}

      %Day{number: number, tasks: tasks, title: title} ->
        %DayReport{
          number: number,
          tasks: tasks,
          title: title,
          total_time_spent: count_tasks_time_spent(tasks)
        }
    end
  end

  @spec count_tasks_time_spent(tasks :: [Task.t()]) :: integer()
  def count_tasks_time_spent(tasks) do
    tasks
    |> Stream.map(fn %Task{time_spent: time_spent} -> time_spent end)
    |> Enum.sum()
  end

  @spec check_task(task :: Task.t()) :: Task.t() | report_builder_error()
  def check_task(%Task{category: category} = task) when category in @task_categories, do: task

  def check_task(task),
    do:
      {:error,
       context:
         "Invalid category #{task.category}. Task category should be from the list: #{Enum.join(@task_categories, ", ")}"}

  @spec build_month_report(month :: Month.t()) :: MonthReport.t()
  def build_month_report(%Month{days: days, number: number, title: title}) do
    days_spent = length(days)

    # with raw_tasks <- Enum.flat_map(days, fn %Day{tasks: tasks} -> tasks end),
    #      validated_tasks <- Enum.map(raw_tasks, &check_task/1),
    #      tasks <- Enum.all?(validated_tasks, fn %Task{} = task -> task end) do

    tasks = Enum.flat_map(days, fn %Day{tasks: tasks} -> tasks end)

    total_time_spent = count_tasks_time_spent(tasks)

    avg_time_spent = trunc(total_time_spent / days_spent)

    initial_categories_report_list =
      Enum.map(@task_categories, fn category ->
        %CategoryReport{title: category, time_spent: 0}
      end)

    categories =
      tasks
      |> Enum.reduce(
        initial_categories_report_list,
        fn %Task{category: category, time_spent: time_spent}, acc ->
          update_in(
            acc,
            [Access.filter(fn report -> report.title == category end), :time_spent],
            &(&1 + time_spent)
          )
        end
      )

    %MonthReport{
      avg_time_spent: avg_time_spent,
      categories: categories,
      days_spent: days_spent,
      number: number,
      title: title,
      total_time_spent: total_time_spent
    }

    # else
    #   {:error, _context} = error -> error
    # end
  end
end
