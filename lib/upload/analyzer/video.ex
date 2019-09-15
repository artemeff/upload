if Code.ensure_compiled?(FFprobe) do
  defmodule Upload.Analyzer.Video do
    @moduledoc false

    @spec get_metadata(Path.t()) :: {:ok, map()} | {:error, binary()}
    def get_metadata(path) do
      case FFprobe.streams(path) do
        {:ok, streams} ->
          {:ok, streams |> find_video() |> extract_metadata()}

        {:error, reason} ->
          {:error, "ffprobe failed (reason: #{inspect(reason)})"}
      end
    end

    defp find_video(streams) do
      Enum.find(streams, %{}, fn stream -> stream["codec_type"] == "video" end)
    end

    defp extract_metadata(video) do
      duration = video |> Map.get("duration") |> to_float()
      ratio = video |> Map.get("display_aspect_ratio") |> to_ratio()
      angle = video |> Map.get("tags", %{}) |> Map.get("rotate") |> to_integer()
      {width, height} = get_dimensions(video, angle, ratio)

      prune(%{
        height: height,
        width: width,
        angle: angle,
        duration: duration,
        display_aspect_ratio: ratio
      })
    end

    defp get_dimensions(video, angle, ratio) do
      encoded_width = video |> Map.get("width") |> to_float()
      encoded_height = video |> Map.get("height") |> to_float()
      computed_height = get_computed_height(encoded_width, ratio)

      if angle in [90, 270] do
        {computed_height || encoded_height, encoded_width}
      else
        {encoded_width, computed_height || encoded_height}
      end
    end

    defp get_computed_height(nil, _), do: nil
    defp get_computed_height(_, nil), do: nil

    defp get_computed_height(width, [numerator, denominator]) do
      width * (to_float(denominator) / numerator)
    end

    defp prune(values) do
      values |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Enum.into(%{})
    end

    defp to_ratio(ratio) when is_binary(ratio) do
      case String.split(ratio, ":") do
        [num, denom] -> Enum.map([num, denom], &to_integer/1)
        _ -> nil
      end
    end

    defp to_ratio(_ratio), do: nil

    defp to_integer(value) when is_integer(value), do: value
    defp to_integer(value) when is_float(value), do: round(value)

    defp to_integer(value) when is_binary(value) do
      {parsed, _} = Integer.parse(value)
      parsed
    end

    defp to_integer(_value), do: nil

    defp to_float(value) when is_integer(value), do: value / 1
    defp to_float(value) when is_float(value), do: value

    defp to_float(value) when is_binary(value) do
      {parsed, _} = Float.parse(value)
      parsed
    end

    defp to_float(_value), do: nil
  end
else
  defmodule Upload.Analyzer.Video do
    def get_metadata(_) do
      {:error, "the ffmpex package is not installed"}
    end
  end
end
