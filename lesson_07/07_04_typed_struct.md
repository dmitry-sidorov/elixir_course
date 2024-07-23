# Struct с указанием типов.

Хотя Эликсир является языком с динамической типизацией, он все же опционально поддерживает и статическую типизацию.

Статическая типизация:
- позволяет исключить определенный класс ошибок;
- дает компилятору больше информации для оптимизации кода;
- улучшает самодокументируемость и читабельность кода.

TODO
The Design Principles of the Elixir Type System
Giuseppe Castagna, Guillaume Duboc, and José Valim
Gradual Set-Theoretic Types
v1.17

В случае с Эликсир есть нюансы, так как компилятор игнорирует атрибуты статической типизации, а все проверки выполняются отдельным тулом **dialyzer** уже после того, как код скопилирован.

https://erlang.org/doc/man/dialyzer.html
Dialyzer, a DIscrepancy AnaLYZer for ERlang programs.

Этот тул изначально был создан для Эрланг. Но он умеет проверять и исходный код Эрланг, и скомпилированный байт-код. В случае с Эликсир dialyzer не может работать с исходным кодом, а проверяет только байт-код.

Вернемся к нашим объектам Event и добавим описания типов:
https://hexdocs.pm/elixir/typespecs.html

TODO MyCalendar.Model.TypedStruct

```shell
$ iex -S mix
```

```elixir-iex
iex(1)> event = Event.sample_typed_struct_event()
%Model.TypedEvent.Event{
  agenda: [
    %Model.TypedEvent.Topic{
```

В iex мы не увидим никакой разницы:

```elixir-iex
iex(3)> i event
Term
  %Model.TypedEvent.Event{...}
Data type
  Model.TypedEvent.Event
```

В коде к уже существующим атрибутам defstruct и @enforce_keys добавился еще аттрибут @type:

```elixir
  defmodule Event do
    @type t :: %__MODULE__{
      title: String.t,
      datetime: DateTime.t,
      location: Location.t,
      participants: list(Participant.t),
      agenda: list(Topic.t)
    }
    @enforce_keys [:title, :datetime, :location, :participants, :agenda]
    defstruct [
      :title,
      :datetime,
      :location,
      :participants,
      :agenda
    ]
  end
```

Мы уже два раза продублировали каждое поле объекта, теперь пришлось повторить поля еще раз. Это, конечно, не самый удобный дизайн языка, который является следствием его постепенного развития. Сперва появлся defstruct, позже @enforce_keys, еще позже @type.

К счастью, есть сторонние библиотеки, реализующие макросы, позволяющие избежать такого дублирования. Но мы пока изучаем Эликсир в его оригинальном виде.

TODO MyCalendar.sample_event_typed_struct()

Давайте намеренно сделаем ошибку и посмотрим, как компилятор и dialyzer будет реагировать на нее:

```elixir
  defmodule Location do
    @type t :: %__MODULE__{
      address: Address.t,
      room: Broom.t
    }
    @enforce_keys [:address, :room]
    defstruct [:address, :room]
  end
```

Собираем проект:

```shell
$ mix compile
Compiling 5 files (.ex)
Generated event app
```

Компилятор никак не реагирует на указание несуществующего типа.


## Подключаем dialyzer

Поскольку dialyzer разработан для Эрланг, напрямую использовать его в Эликсир проекте сложно. К счастью, есть сторонняя библиотека, которая делает эту задачу тривиальной.

Библиотеку нужно указать как зависимость в файле mix.exs:

```elixir
  defp deps do
    [
      {:dialyxir, "~1.2", only: [:dev], runtime: false}
    ]
  end
```

Пока не будем вдаваться в детали, про управление зависимостями будет отдельная тема.

Подключаем зависимость и собираем проект:

```shell
mix deps.get
mix compile
```

И теперь можно запускать dialyzer:

```shell
mix dialyzer
```

Первый запуск будет долгим. Сперва dialyzer формирует специальный файл PLT (Persistent Lookup Table), куда включена информация обо всех модулях проекта, сторонних библиотеках, стандартных библиотеках Эликсира и Эрланга. Такой файл уникален для проекта и используемых в нем версий Эликсир и Эрланг.

Затем PLT используется для статического анализа кода проекта. Повторные запуски работают быстро, потому что PLT-файл уже существует и его не нужно создавать заново. Иногда его нужно будет обновлять: при смене версий Эликсир и Эрланг или обновлении библиотек.

Результат анализа:

```shell
Starting Dialyzer
...
Total errors: 1, Skipped: 0, Unnecessary Skips: 0
done in 0m1.11s
:0:unknown_type
Unknown type: Broom.t/0.
```

Ошибка найдена. Исправим ее и запустим анализ снова:

```shell
Starting Dialyzer
...
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done in 0m1.12s
done (passed successfully)
```

dialyzer проверяет не только типы данных, но и правильность вызовов функций (вызванные функции и модули действительно существуют), правильность передачи им аргументов, неиспользуемые ветки кода и другие проблемы. Если типы данных не указаны, то во многих случаях dialyzer может вывести их сам.

К сожалению, многие разработчики этот тул игнорируют. Но чаще бывает, что используют, но нерегулярно. Из-за того, что dialyzer запускается отдельно от компилятора, его просто забывают запускать. В результате в коде проекта накапливаются невыявленные проблемы, и потом бывает сложно их исправить.

Эту проблему решает встраивание запуска dialyzer в процесс CI, наряду с запуском тестов.
