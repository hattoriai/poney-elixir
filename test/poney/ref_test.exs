defmodule Poney.RefTest do
  use ExUnit.Case, async: true
  doctest Poney.Ref

  alias Poney.Ref

  test "every form reads and writes back the same" do
    for key <-
          ~w(entity:order-service relationship:r1 useCase:checkout dataFlow:f1 dataRelation:d1 behavior:b1
                  dataType:orders dataType:orders#status group:arch:zone-a message:checkout:m1 fragment:checkout:f1
                  state:order-lifecycle:paid transition:order-lifecycle:t-retry activityNode:a:n1 activityFlow:a:f1) do
      assert {:ok, ref} = Ref.parse(key)
      assert to_string(ref) == key
    end
  end

  test "text that is not a ref" do
    for text <- ["entity", "entity:", "planet:earth", "state:only-machine", "group:view"],
        do: assert(Ref.parse(text) == :error)
  end
end
