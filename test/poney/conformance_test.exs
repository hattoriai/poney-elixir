defmodule Poney.ConformanceTest do
  # The specification's conformance suite (spec/conformance): a conforming
  # reader accepts every valid document, refuses every invalid one, and
  # reports an error at each path the manifest lists.
  use ExUnit.Case, async: true

  alias Poney.Fixtures

  for %{"file" => file, "valid" => valid, "rule" => rule} = c <- Fixtures.conformance() do
    @case c

    test "#{if valid, do: "accepts", else: "refuses"} #{file} (#{rule})" do
      doc = Fixtures.conformance(@case["file"])
      errors = for %{severity: :error} = i <- Poney.check(doc), do: i.path

      if @case["valid"] do
        assert errors == []
        assert {:ok, %Poney.Document{}} = Poney.read(doc)
      else
        assert {:error, _} = Poney.read(doc)

        for path <- @case["errorPaths"] || [],
            do: assert(path in errors, "no error at #{path}: #{inspect(errors)}")
      end

      # Shape faults (§4) fail the published schema too; every other case fits it.
      assert JSV.validate(doc, Fixtures.jsv()) |> elem(0) ==
               if(@case["rule"] == "§4", do: :error, else: :ok)
    end
  end

  for name <- ~w(kestrel-commerce tour walkthrough) do
    test "reads the published example #{name}" do
      doc = Fixtures.example(unquote(name))
      assert {:ok, %Poney.Document{}} = Poney.read(doc)
      assert for(%{severity: :error} = i <- Poney.check(doc), do: i) == []
    end
  end
end
