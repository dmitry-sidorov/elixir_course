# Протокол

Мы уже знаем, что модуль Enum работает с самыми разными коллециями: list, map, string, range и другими.

```
iex(1)> Enum.map([1,2,3], fn(i) -> i * 2 end)
[2, 4, 6]

iex(2)> Enum.map('Hello', fn(char) -> char + 1 end)
'Ifmmp'

iex(3)> Enum.map(1..10, fn(i) -> i * i end)
[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

iex(5)> Enum.map(%{a: 1, b: 2}, fn({k, v}) -> {v, k} end)
[{1, :a}, {2, :b}]
```


Это можно было бы реализовать примерно так:
```
def map(value, fn) when is_list(value), do: ...
def map(value, fn) when is_map(value), do: ...
```

Такой вариант плохо масштабируется. Нам пришлось бы вносить изменения в модуль Enum каждый раз, когда мы хотим добавить новую коллекцию. В Эликсире это сделано лучше -- с помощью протоколов.

Протоколы очень похожи на интерфейсы в Java. Они описывают некий набор функций, с известными аргументами и возвращаемыми значениями, но без реализации.

Например, протокол Enumerable описывает какие функции должна реализовать новая коллекция, чтобы модуль Enum мог с ней работать. Добавление новой коллекции для Enum реализуется в модуле коллекции, а не в модуле Enum. Таким образом коллекции можно добавлять без изменений в Enum.

Рассмотрим пример. Допустим, у нас есть модуль Calendar, который умеет хранить и отображать некие CalendarItem с привязкой ко времени. CalendarItem описаны протоколом, так что Calendar не знает, какие конкретные реализации уже есть и еще будут. Например, у нас уже есть несколько Event с разными реализациями, которые хотелось бы добавлять в Calendar. А потом, вероятно, появятся еще какие-то CalendarItem.


Модуль Calendar будет очень простым. Он умеет принимать item, хранить их в списке, и как-то отображать.
```
defmodule Model.Calendar do
...
```

Протокол CalendarItems описывает две функции: datetime и description:
```
defprotocol Model.CalendarItem do
...
```

Теперь реализуем этот протокол для наших Event разного типа:
```
defimpl Model.CalendarItem, for: [Model.Event.Event, Model.TypedEvent.Event] do
...
defimpl Model.CalendarItem, for: Map do
...
```

И теперь Calendar может работать с ними:

```
alias Model.Calendar, as: C
c = C.new

e1 = TypedStructExample.create
e2 = StructExample.create
e3 = SimpleExample.create_map
c = C.add_item(c, e1)
c = C.add_item(c, e2)
c = C.add_item(c, e3)
C.show(c)
```

У нас есть еще одна реализация Event, на базе кортежа. Мы не реализовывали протокол CalendarItem для нее. И если мы попробуем добавить в календарь такое событие:
```
e4 = SimpleExample.create
c = C.add_item(c, e4)
C.show(c)

** (Protocol.UndefinedError) protocol Model.CalendarItem not implemented for {:event, ...
```
то получим исключение.

Компилятор Эликсир автоматически создает тип для протокола, в нашем случае CalendarItem.t. И мы можем использовать этот тип в описании функции:
```
@spec add_item(t, CalendarItem.t) :: t
```
К сожалению, dialyzer не ловит ошибку:
```
c = C.add_item(c, e4)
```
Так что мы узнаем об этом только в рантайме.

Даже в таких очевидных случаях
```
Enum.map(:not_an_enum, fn(i) -> i end)
```
dyalyzer не находит ошибок.


## Стандартные протоколы

В Elixir есть 5 стандартных протоколов:
- Enumerable
- Collectable
- Inspect
- List.Chars
- String.Chars

Рассмотрим их по-очереди.


### Enumerable

https://hexdocs.pm/elixir/Enumerable.html

Enumerable -- пожалуй, самый часто используемый протокол. Модуль Enum находится в центре любой работы с коллекциями, и любая коллекция реализует Enumerable.

Модуль Stream тоже работает с коллекциями через этот протокол.

Протокол содержит 4 функции: count, member?, reduce, slice. Все многообразие функций модуля Enum реализовано через эти 4 функции.

Теоретически достаточно только reduce. Все остальное -- count, map, filter, slice, any, take и даже sort можно реализовать через reduce. Но на практике это не очень эффективно. Например, member? для Map выполняется за константное время, тогда как реализация на основе reduct была бы O(n).

Enumerable.reduce это не то же самое, что Enum.reduce. Там более сложная реализация, где можно управлять итерацией -- останавливать, возобновлять и прерывать. Это позволяет более эффективно реализовывать остальные функции, не проходя всю коллекцию до конца, если это не нужно, или итерироваться по двум коллециям одновременно.


### Collectable

https://hexdocs.pm/elixir/Collectable.html

Этот протокол в некотором роде противоположность Enumerable. Если идея Enumerable -- итерироваться по коллекции, то есть, по очереди извлекать из нее элементы; то идея Collectable -- собирать коллекцию, добавляя в нее элементы.

Зачем это нужно? Это тоже нужно для модуля Enum. Дело в том, что функции модуля Enum на входе принимают любые коллекции, но на выходе у них всегда список. А что, если нужен не список? Для этого есть функция Enum.into, которая преобразует список в другую коллекцию, реализующую Collectable.

```
iex(1)> my_map = %{a: 1, b: 2}
%{a: 1, b: 2}
iex(3)> Enum.map(my_map, fn({k, v}) -> {k, v + 1} end)
[a: 2, b: 3]
iex(4)> Enum.map(my_map, fn({k, v}) -> {k, v + 1} end) |> Enum.into(%{})
%{a: 2, b: 3}
```

Протокол Collectable описывает, как получить нужную коллекцию из списка. Протокол содержит только одну функцию -- into. И каждая коллекция, которая хочет работать с Enum.into, реализует её.

Аналогично это работает с конструкторами списков:
```
iex(8)> for {k,v} <- my_map, do: {k, v + 1}
[a: 2, b: 3]
iex(9)> for {k,v} <- my_map, into: %{}, do: {k, v + 1}
%{a: 2, b: 3
```


### Inspect

TODO stopped here

https://hexdocs.pm/elixir/Inspect.html

The Inspect protocol is the protocol used to transform any data structure into a readable textual representation.


Мы не раз видели в iex, как отображаются разные значения. Это делает функция Kernel.inspect

```
TODO примеры
```

inspect не редко используется в логировании
```
require Logger
Logger.info("data is #{inspect data})
```



### List.Chars

https://hexdocs.pm/elixir/List.Chars.html


### String.Chars

https://hexdocs.pm/elixir/String.Chars.html

String.Chars protocol, which specifies how to convert a data structure to its human representation as a string. It’s exposed via the to_string function

Важно для сериализации данных в строковый формат, например, JSON.


## Критика протоколов

Некоторые разработчики оспаривают пользу протоколов или прямо называют их ненужными.

В языке Эрланг их нет, и там каждый модуль -- map, lists, sets -- самостоятельно реализует функции map, filter, fold и др.

Например:
```
> MyMap = #{k => 1, v => 2}.
> MyFun = fun(K, V) -> V + 1 end.
> maps:map(MyFun, MyMap).
#{k => 2,v => 3}
```
концептуально проще, даже если вы не знакомы с синтаксисом Эрланг.

Тогда как
```
%{a: 1, b: 2}
|> Enum.map(fn({k,v}) -> {k, v + 1} end)
|> Enum.into(%{})
```
концептуально сложнее.

На мой взгляд протоколы Enumerable, Collectable не самые удачные примеры протоколов. И это потому, что в целом модуль Enum -- не самое удачное архитектурное решение.

Зато Inspect и String.Chars -- это хорошие, полезные протоколы.

Как бы там ни было, вам придется иметь дело с протоколами, если не в своем коде, то в чужом. Поэтому важно знать, как они работают.