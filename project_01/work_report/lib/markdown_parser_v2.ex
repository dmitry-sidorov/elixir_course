defmodule WorkReport.MarkdownParserV2 do
  @moduledoc """
  This module is markdown syntax specific parser of work report.
  Function parse_report() recieves binary content of the file and returns list of models.
  """
  alias WorkReport.Model.{Day, Month, Task}
  alias WorkReport.Parser

  @behaviour Parser

  @minutes_in_one_hour 60

  @type parser_error :: {:error, String.t(), context: term()}

  @impl Parser
  def parse_report(report, _opts \\ []) do
    result =
      report
      |> String.split("\n")
      |> Enum.reject(fn str -> str == "" end)
      |> Enum.map(&map_entity_string/1)

    # |> Stream.map(fn month_string -> String.split(month_string, "\n\n") end)
    # |> Enum.map(fn [month_string | day_string_list] ->
    #   month = parse_month_string(month_string)
    #   days = day_string_list |> Enum.map(&parse_day/1)
    #   Map.put(month, :days, days)
    # end)

    {:ok, result}
  end

  def map_entity_string(str) do
    cond do
      %{"month_title" => title} = Regex.named_captures(~r/^#\s(?<month_title>\w+)$/, str) ->
        %Month{number: get_month_number(title), title: title}

      %{"number" => number, "day_title" => title} =
          Regex.named_captures(~r/^##\s(?<number>\d+)\s(?<day_title>\w+)$/, str) ->
        %Day{number: String.to_integer(number), title: title}

      %{"category" => category, "description" => description, "time_spent" => time_spent} =
          Regex.named_captures(
            ~r/^\[(?<category>\w+)\]\s(?<description>.+)\s\-\s(?<time_spent>(\d{0,2}h)?\s?(\d{0,2}m)?)$/,
            str
          ) ->
        %Task{category: category, description: description, time_spent: parse_time(time_spent)}

      true ->
        {:error, "wrong_entity_fomat"}
    end
  end

  @spec parse_month_string(month_string :: String.t()) :: Month.t() | parser_error()
  def parse_month_string(month_string) do
    case Regex.named_captures(~r/^#\s(?<month_title>\w+)$/, month_string) do
      %{"month_title" => title} -> %Month{number: get_month_number(title), title: title}
      nil -> {:error, "wrong_month_string_format", context: month_string}
    end
  end

  @spec get_month_number(month_title :: String.t()) :: integer() | nil
  def get_month_number(month_title) do
    case month_title do
      "January" -> 1
      "February" -> 2
      "March" -> 3
      "April" -> 4
      "May" -> 5
      "June" -> 6
      "July" -> 7
      "August" -> 8
      "September" -> 9
      "October" -> 10
      "November" -> 11
      "December" -> 12
      _ -> raise InvalidMonthTitleError, month_title
    end
  end

  @spec parse_day(full_day_string :: binary()) :: Day.t()
  def parse_day(full_day_string) do
    [day_string | task_string_list] =
      String.split(full_day_string, "\n") |> Enum.reject(fn str -> str == "" end)

    parse_day_string(day_string) |> parse_task_list(task_string_list)
  end

  @spec parse_day_string(day_string :: binary()) :: Day.t() | parser_error()
  def parse_day_string(day_string) do
    regexp = ~r/^##\s(?<number>\d+)\s(?<title>\w+)$/

    case Regex.named_captures(regexp, day_string) do
      %{"number" => number, "title" => title} ->
        %Day{number: String.to_integer(number), title: title}

      nil ->
        {:error, "wrong_day_string_format", context: day_string}
    end
  end

  @spec parse_task_list(day :: Day.t(), task_string_list :: [binary()]) :: Day.t()
  def parse_task_list(day, task_string_list) do
    tasks = Enum.map(task_string_list, &parse_task/1) |> Enum.reject(&is_nil/1)

    Map.put(day, :tasks, tasks)
  end

  @spec parse_task(task :: binary()) :: Task.t() | parser_error()
  def parse_task(task) do
    # Regexp to parse task string format: [Type] Some title - 1h 30m
    regexp =
      ~r/^\[(?<category>\w+)\]\s(?<description>.+)\s\-\s(?<time_spent>(\d{0,2}h)?\s?(\d{0,2}m)?)$/

    case Regex.named_captures(regexp, task) do
      %{"category" => category, "description" => description, "time_spent" => time_spent} ->
        %Task{category: category, description: description, time_spent: parse_time(time_spent)}

      nil ->
        {:error, "wrong_task_string_format", context: task}
    end
  end

  @spec parse_time(String.t()) :: integer()
  def parse_time(time_string) do
    %{"hours" => hours, "minutes" => minutes} =
      Regex.named_captures(~r/^((?<hours>\d{0,2})h)?\s?((?<minutes>\d{0,2})m)?$/, time_string)

    string_to_int(hours) * @minutes_in_one_hour + string_to_int(minutes)
  end

  def string_to_int(""), do: 0
  def string_to_int(str), do: String.to_integer(str)
end
