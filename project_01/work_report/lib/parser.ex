defmodule WorkReport.Parser do
  @moduledoc """
  Interface for report parser.
  """
  alias WorkReport.Model.Month

  @callback parse_report(report :: binary(), opts :: Keyword.t()) ::
              {:ok, [Month.t()]} | {:error, String.t()}

  @spec build_month_model(report_file_path :: binary(), opts :: Keyword.t()) ::
          {:ok, [Month.t()]} | {:error, String.t()}
  def build_month_model(report_file_path, opts) do
    with {parser, opts} <- Keyword.pop(opts, :parser),
         {:ok, file} <- File.read(report_file_path),
         {:ok, result} <- parser.parse_report(file, opts) do
      {:ok, result}
    else
      {:error, :enoent} -> {:error, "file-does-not-exist"}
      error -> error
    end
  end
end
