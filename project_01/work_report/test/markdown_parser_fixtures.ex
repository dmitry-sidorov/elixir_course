defmodule MarkdownParserTestFixtures do
  import CommonTestFixtures

  def single_month_fixture do
    Map.put(month_fixture(variant: 1), :days, [
      Map.put(day_fixture(variant: 1), :tasks, [
        task_fixture(variant: 1),
        task_fixture(variant: 2)
      ]),
      Map.put(day_fixture(variant: 2), :tasks, [
        task_fixture(variant: 3),
        task_fixture(variant: 4)
      ])
    ])
  end

  def plural_month_fixture() do
    [
      single_month_fixture(),
      Map.put(month_fixture(variant: 2), :days, [
        Map.put(day_fixture(variant: 3), :tasks, [
          task_fixture(variant: 5),
          task_fixture(variant: 6)
        ]),
        Map.put(day_fixture(variant: 4), :tasks, [
          task_fixture(variant: 7),
          task_fixture(variant: 8)
        ])
      ])
    ]
  end
end
