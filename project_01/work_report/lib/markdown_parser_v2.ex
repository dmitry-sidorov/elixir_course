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
  @type entity :: Month.t() | Day.t() | Task.t()

  @impl Parser
  def parse_report(report, _opts \\ []) do
    result =
      report
      |> String.split("\n")
      |> Stream.reject(fn str -> str == "" end)
      |> Enum.map(&map_entity_string/1)
      |> build_entity_list()

    {:ok, result}
  end

  @spec build_entity_list(
          entities :: [entity()],
          acc :: [Month.t()],
          pointer :: %{day: integer(), month: integer()}
        ) :: [Month.t()]
  def build_entity_list([], acc, _pointer), do: Enum.reverse(acc)

  def build_entity_list([entity | rest_entities], acc \\ [], pointer \\ %{day: -1, month: -1}) do
    case entity do
      %Month{number: number} ->
        build_entity_list(
          rest_entities,
          [entity | acc],
          Map.put(pointer, :month, number)
        )

      %Day{number: number} ->
        build_entity_list(
          rest_entities,
          update_in(
            acc,
            [Access.filter(fn item -> item.number == pointer.month end), :days],
            &(&1 ++ [entity])
          ),
          Map.put(pointer, :day, number)
        )

      %Task{} ->
        build_entity_list(
          rest_entities,
          update_in(
            acc,
            [
              Access.filter(fn item -> item.number == pointer.month end),
              :days,
              Access.filter(fn item -> item.number == pointer.day end),
              :tasks
            ],
            &(&1 ++ [entity])
          ),
          pointer
        )

      _ ->
        build_entity_list(rest_entities, [{:error, "unprocessible_entity"} | acc], pointer)
    end
  end

  @spec map_entity_string(str :: binary) :: entity() | parser_error()
  def map_entity_string(str) do
    cond do
      Regex.match?(~r/^#\s\w+$/, str) ->
        parse_month_string(str)

      Regex.match?(~r/^##\s\d+\s\w+$/, str) ->
        parse_day_string(str)

      Regex.match?(
        ~r/^\[(\w+)\]\s(.+)\s\-\s((\d{0,2}h)?\s?(\d{0,2}m)?)$/,
        str
      ) ->
        parse_task(str)

      true ->
        {:error, "wrong_entity_format", context: str}
    end
  end

  @spec parse_month_string(month_string :: String.t()) :: Month.t() | parser_error()
  def parse_month_string(month_string) do
    case Regex.named_captures(~r/^#\s(?<month_title>\w+)$/, month_string) do
      %{"month_title" => title} -> %Month{number: get_month_number(title), title: title}
      nil -> {:error, "wrong_month_string_format", context: month_string}
    end
  end

  @spec get_month_number(month_title :: String.t()) :: integer() | parser_error()
  def get_month_number(month_title) do
    case String.downcase(month_title) do
      "january" -> 1
      "february" -> 2
      "march" -> 3
      "april" -> 4
      "may" -> 5
      "june" -> 6
      "july" -> 7
      "august" -> 8
      "september" -> 9
      "october" -> 10
      "november" -> 11
      "december" -> 12
      _ -> {:error, "invalid_month_name", context: month_title}
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
    tasks = Enum.map(task_string_list, &parse_task/1)

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

  @spec parse_time(String.t()) :: integer() | parser_error()
  def parse_time(time_string) do
    case Regex.named_captures(~r/^((?<hours>\d{0,2})h)?\s?((?<minutes>\d{0,2})m)?$/, time_string) do
      %{"hours" => hours, "minutes" => minutes} ->
        string_to_int(hours) * @minutes_in_one_hour + string_to_int(minutes)

      nil ->
        {:error, "wrong_time_string_format", context: time_string}
    end
  end

  @spec string_to_int(str :: binary() | any()) :: integer() | parser_error()
  def string_to_int(""), do: 0

  def string_to_int(str) when is_binary(str) do
    case Regex.match?(~r/^\d+$/, str) do
      true -> String.to_integer(str)
      false -> {:error, "string_is_not_convertable_to_integer", context: str}
    end
  end

  def string_to_int(str), do: {:error, "not_binary_argument", context: str}
end
