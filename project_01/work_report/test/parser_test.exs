defmodule ParserTest do
  use ExUnit.Case
  import CommonTestFixtures

  alias WorkReport.Parser

  defmodule MockSuccessParser do
    @behaviour Parser

    def parse_report(_report_binary, _opts) do
      {:ok, [month_fixture(variant: 1)]}
    end
  end

  describe "parser" do
    test "should return correct model" do
      assert Parser.build_month_model("test/sample/single-report.md", parser: MockSuccessParser) ==
               {:ok, [month_fixture(variant: 1)]}
    end

    test "should return error, if there's wrong path to file" do
      assert Parser.build_month_model("not_exist", parser: MockSuccessParser) ==
               {:error, "file-does-not-exist"}
    end
  end
end
