defmodule Mix.Tasks.Poney.Spec do
  @shortdoc "Copies the Poney specification files from a tagged release"

  @moduledoc """
  Copies the files that define the Poney format from a release of Poney.

      $ mix poney.spec v0.2.0
      $ mix poney.spec v0.2.0 --from ../poney

  This task is for work on this library itself; in any other project it
  stops with an error. It copies, from the tag given:

    * `spec/poney.schema.json` to `priv/spec/poney.schema.json`: the shape
      that `Poney.read/1` checks;
    * `spec/conformance/` to `test/conformance/`: the documents that every
      reader must accept or refuse, and the manifest that says which;
    * `spec/examples/*.poney` to `test/fixtures/examples/`.

  It then writes `priv/spec/source.json` with the tag. Without `--from`, it
  downloads the files from GitHub; with `--from`, it reads them from a
  checkout of Poney at that tag (`git show <tag>:<path>`).
  """

  use Mix.Task

  @repository "hattoriai/poney"
  @examples ~w(kestrel-commerce.poney tour.poney walkthrough.poney)

  @impl Mix.Task
  def run(args) do
    if Mix.Project.config()[:app] != :poney,
      do:
        Mix.raise(
          "mix poney.spec is for work on the Poney library itself; it replaces its copy of the specification"
        )

    case OptionParser.parse(args, strict: [from: :string]) do
      {opts, [tag], []} -> copy(tag, opts[:from])
      _ -> Mix.raise("Usage: mix poney.spec <tag> [--from <path to a Poney checkout>]")
    end
  end

  defp copy(tag, from) do
    read = reader(tag, from)
    write("priv/spec/poney.schema.json", read.("spec/poney.schema.json"))

    manifest = read.("spec/conformance/manifest.json")
    File.rm_rf!("test/conformance")
    write("test/conformance/manifest.json", manifest)

    for %{"file" => file} <- JSON.decode!(manifest)["cases"] do
      write("test/conformance/#{file}", read.("spec/conformance/#{file}"))
    end

    for file <- @examples,
        do: write("test/fixtures/examples/#{file}", read.("spec/examples/#{file}"))

    write(
      "priv/spec/source.json",
      JSON.encode!(%{"repository" => @repository, "tag" => tag}) <> "\n"
    )

    Mix.shell().info("Copied the Poney specification at #{tag}")
  end

  # Mix's own download, which verifies the server's certificate.
  defp reader(tag, nil) do
    fn path ->
      url = "https://raw.githubusercontent.com/#{@repository}/#{tag}/#{path}"

      case Mix.Utils.read_path(url) do
        {:ok, body} -> body
        other -> Mix.raise("GET #{url}: #{inspect(other)}")
      end
    end
  end

  defp reader(tag, checkout) do
    fn path ->
      case System.cmd("git", ["-C", checkout, "show", "#{tag}:#{path}"], stderr_to_stdout: true) do
        {body, 0} -> body
        {out, _} -> Mix.raise("git show #{tag}:#{path} in #{checkout}: #{String.trim(out)}")
      end
    end
  end

  defp write(path, body) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end
end
