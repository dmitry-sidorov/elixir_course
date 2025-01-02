defmodule CommonTestFixtures do
  alias WorkReport.Model.{Day, Month, Task}

  def month_fixture(opts \\ []) do
    variant = Keyword.get(opts, :variant, 5)

    case variant do
      1 -> %Month{number: 6, title: "June", days: []}
      2 -> %Month{number: 8, title: "August", days: []}
    end
  end

  def day_fixture(opts \\ []) do
    variant = Keyword.get(opts, :variant)

    case variant do
      1 ->
        %Day{
          number: 5,
          title: "tue",
          tasks: []
        }

      2 ->
        %Day{
          number: 6,
          title: "wed",
          tasks: []
        }

      3 ->
        %Day{
          number: 10,
          title: "mon",
          tasks: []
        }

      4 ->
        %Day{
          number: 12,
          title: "wed",
          tasks: []
        }
    end
  end

  def task_fixture(opts \\ []) do
    variant = Keyword.get(opts, :variant)

    case variant do
      1 ->
        %Task{
          description: "Review Pull Requests",
          time_spent: 27,
          category: "DEV"
        }

      2 ->
        %Task{
          description: "Daily Meeting",
          time_spent: 15,
          category: "COMM"
        }

      3 ->
        %Task{
          description: "Daily Meeting",
          time_spent: 31,
          category: "COMM"
        }

      4 ->
        %Task{
          description: "TASK-42 Read BA documents",
          time_spent: 15,
          category: "DOC"
        }

      5 ->
        %Task{
          description: "Review Pull Requests",
          time_spent: 10,
          category: "DEV"
        }

      6 ->
        %Task{
          description: "Daily Meeting",
          time_spent: 20,
          category: "COMM"
        }

      7 ->
        %Task{
          description: "Daily Meeting",
          time_spent: 10,
          category: "COMM"
        }

      8 ->
        %Task{
          description: "Read API documentation",
          time_spent: 40,
          category: "DOC"
        }
    end
  end
end
