defmodule Solution1 do

  alias BookShop.Model, as: M
  alias BookShop.Validator, as: V
  
  @spec handle(M.json) :: {:ok, M.Order.t} | {:error, term}
  def handle(data) do
    case V.validate_incoming_data(data) do
      {:ok, data} ->

        case V.validate_cat(data["cat"]) do
          {:ok, cat} ->

            case V.validate_address(data["address"]) do
              {:ok, address} ->

                maybe_books = Enum.map(
                  data["books"],
                  fn(book_data) -> M.Book.get_book(book_data["author"], book_data["title"]) end
                )
                
                books_or_error = Enum.reduce(
                  maybe_books,
                  [],
                  fn
                    (_, {:error, _} = acc) -> acc
                    ({:ok, book}, acc) -> [book | acc]
                    ({:error, _} = e, _) -> e
                  end
                )

                case books_or_error do
                  books when is_list(books) ->
                    order = M.Order.new(cat, address, books)
                    {:ok, order}
                  {:error, error} -> {:error, error}
                end

              {:error, error} -> {:error, error}
            end

          {:error, error} -> {:error, error}
        end

      {:error, error} -> {:error, error}
    end
  end
  
end

