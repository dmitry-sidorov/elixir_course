defmodule WorkReport.AccessStruct do
  @moduledoc """
  Macro injects access behaviour to user struct and allows to use Access functions for custom structure.
  E. g., update_in function is very handy to update deeply nested structures.
  """
  defmacro __using__(_opts) do
    quote do
      @impl Access
      def fetch(term, key), do: Map.fetch(term, key)

      @impl Access
      def get_and_update(data, key, update_fn), do: Map.get_and_update(data, key, update_fn)

      @impl Access
      def pop(term, key, default \\ nil), do: Map.pop(term, key, default)
    end
  end
end
