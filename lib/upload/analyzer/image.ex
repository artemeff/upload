defmodule Upload.Analyzer.Image do
  @behaviour Upload.Analyzer

  alias Upload.Utils

  @flags ~w(-format %w|%h|%[orientation])
  @rotated ~w(RightTop LeftBottom)

  @impl true
  def accept?("image/" <> _), do: true
  def accept?(_), do: false

  @impl true
  def analyze(path) do
    case Utils.cmd(:identify, @flags ++ [path]) do
      {:ok, out} ->
        {:ok, parse(out)}

      {:error, :enoent} ->
        Utils.log("Skipping image analysis because ImageMagick is not installed", :warn)
        {:ok, %{}}

      {:error, {:exit, 1}} ->
        Utils.log("Skipping image analysis because ImageMagick doesn't support the file", :warn)
        {:ok, %{}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse(out) do
    out
    |> String.trim()
    |> String.split("|")
    |> rotate()
    |> Enum.map(&String.to_integer/1)
    |> rzip([:width, :height])
    |> Enum.into(%{})
  end

  defp rzip(a, b), do: Enum.zip(b, a)
  defp rotate([w, h, o]) when o in @rotated, do: [h, w]
  defp rotate([w, h, _]), do: [w, h]
end
