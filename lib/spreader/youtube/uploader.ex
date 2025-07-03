defmodule Spreader.YouTube.Uploader do
  @moduledoc """
  High-level API for uploading videos to YouTube using the resumable
  `videos.insert` protocol. This module is **stateless** – callers pass in the
  `Spreader.Accounts.User` struct and a readable `IO` device or binary.

  Typical usage:

      {:ok, video_id} =
        user
        |> Spreader.YouTube.Uploader.upload(
          filepath: "/tmp/my.mov",
          title: "Demo",
          description: "Uploaded from Spreader"
        )

  For large files the upload happens in chunks (8 MiB default).
  Processing status is polled until it reaches `succeeded`.
  """

  alias GoogleApi.YouTube.V3.Api.Channels
  alias GoogleApi.YouTube.V3.Api.Videos
  alias GoogleApi.YouTube.V3.Model.{Video, VideoSnippet, VideoStatus}
  alias Spreader.Accounts
  alias Spreader.YouTube.Client
  require Logger

  @chunk 8 * 1024 * 1024

  @doc """
  Convenience helper when you already have the video on disk.
  """
  @spec upload(Accounts.User.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def upload(user, opts) when is_list(opts) do
    with {:ok, conn} <- Client.connection(user),
         {:ok, %{channel_id: _channel_id, user: _user}} <- ensure_channel_id(user, conn),
         {:ok, upload_url} <- init_resumable(conn, opts),
         {:ok, body} <- send_file(upload_url, opts[:filepath]),
         {:ok, video_id} <- complete_processing(conn, body) do
      {:ok, video_id}
    else
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  # -------------------------------------------------------------------------
  # Internal helpers
  # -------------------------------------------------------------------------

  defp ensure_channel_id(user, conn) do
    tokens = user.tokens || %{}

    case Map.get(tokens, "youtube_channel_id") do
      nil ->
        # Fetch channel id via API and persist
        with {:ok, %GoogleApi.YouTube.V3.Model.ChannelListResponse{items: [item | _]}} <-
               Channels.youtube_channels_list(conn, "id", mine: true),
             %{id: cid} <- Map.from_struct(item),
             {:ok, user} <- Accounts.merge_tokens(user, %{"youtube_channel_id" => cid}) do
          {:ok, %{channel_id: cid, user: user}}
        else
          _ -> {:error, :channel_id_fetch_failed}
        end

      cid ->
        {:ok, %{channel_id: cid, user: user}}
    end
  end

  defp init_resumable(conn, opts) do
    metadata = build_video_metadata(opts)

    conn
    |> Videos.youtube_videos_insert_resumable(["snippet", "status"], "resumable", body: metadata)
    |> handle_resumable_response()
  end

  defp build_video_metadata(opts) do
    %Video{
      snippet: %VideoSnippet{
        title: opts[:title] || Path.basename(opts[:filepath]),
        description: opts[:description] || "",
        tags: opts[:tags] || []
      },
      status: %VideoStatus{privacyStatus: opts[:privacy] || "private"}
    }
  end

  defp handle_resumable_response({:ok, %Tesla.Env{status: 200, headers: headers}}) do
    upload_url = headers |> Enum.into(%{}) |> Map.get("location")
    if upload_url, do: {:ok, upload_url}, else: {:error, :no_location_header}
  end

  defp handle_resumable_response({:ok, %Tesla.Env{status: status}}) do
    {:error, {:unexpected_status, status}}
  end

  defp handle_resumable_response({:error, err}) do
    {:error, err}
  end

  defp handle_resumable_response(_) do
    {:error, :unknown_response}
  end

  defp send_file(_upload_url, nil), do: {:error, :no_filepath_provided}

  defp send_file(upload_url, filepath) do
    Logger.info("[YouTube] Uploading file #{filepath} to #{upload_url}")
    file = File.stream!(filepath, [], @chunk)

    Enum.reduce_while(Stream.with_index(file), {0, :ok}, fn {chunk, _idx}, {offset, _} ->
      chunk_size = byte_size(chunk)
      range = "bytes #{offset}-#{offset + chunk_size - 1}/*"

      headers = [
        {"Content-Length", Integer.to_string(chunk_size)},
        {"Content-Range", range}
      ]

      case :hackney.request(:put, upload_url, headers, chunk, []) do
        {:ok, 308, hdrs, _} ->
          range_end =
            hdrs |> Enum.into(%{}) |> Map.get("range") |> parse_range_end(offset + chunk_size - 1)

          {:cont, {range_end + 1, :ok}}

        {:ok, 201, _hdrs, client_ref} ->
          {:ok, body} = :hackney.body(client_ref)
          {:halt, {:done, body}}

        {:ok, status, _hdrs, client_ref} ->
          {:ok, body} = :hackney.body(client_ref)
          Logger.error("[YouTube] upload failed #{status}: #{body}")
          {:halt, {:error, status}}

        err ->
          Logger.error("[YouTube] upload chunk error: #{inspect(err)}")
          {:halt, {:error, err}}
      end
    end)
    |> case do
      {:done, body} -> {:ok, body}
      {:error, reason} -> {:error, reason}
      {_offset, :ok} -> {:error, :unexpected_finish}
    end
  end

  # After the resumable upload finishes, YouTube will still process the video
  # (transcoding, generating thumbnails, etc.). We poll the API until the
  # processing status becomes "succeeded" (or we give up after a number of
  # attempts).
  @max_processing_attempts 10
  @processing_interval_ms 3_000

  defp complete_processing(conn, body) do
    with {:ok, %{"id" => id}} <- Jason.decode(body),
         :ok <- wait_until_processed(conn, id) do
      {:ok, id}
    else
      {:error, _} = err -> err
      _ -> {:error, :processing_failed}
    end
  end

  defp wait_until_processed(conn, id, attempts_left \\ @max_processing_attempts)
  defp wait_until_processed(_conn, _id, 0), do: {:error, :timeout}

  defp wait_until_processed(conn, id, attempts_left) do
    case video_processing_status(conn, id) do
      {:ok, "succeeded"} ->
        :ok

      {:ok, status} when status in ["processing", "pending"] ->
        Process.sleep(@processing_interval_ms)
        wait_until_processed(conn, id, attempts_left - 1)

      {:ok, other} ->
        Logger.error("[YouTube] unexpected processing status #{other} for #{id}")
        {:error, :unexpected_status}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp video_processing_status(conn, id) do
    case Videos.youtube_videos_list(conn, "processingDetails", id: id) do
      {:ok, %GoogleApi.YouTube.V3.Model.VideoListResponse{items: [%{processingDetails: pd}]}} ->
        {:ok, pd.processingStatus}

      {:ok, %GoogleApi.YouTube.V3.Model.VideoListResponse{items: []}} ->
        {:error, :not_found}

      {:error, err} ->
        Logger.error("[YouTube] processing status error: #{inspect(err)}")
        {:error, err}
    end
  end

  # Parse end index from "Range" header (e.g., "bytes=0-524287")
  defp parse_range_end(nil, default), do: default

  defp parse_range_end("bytes=" <> range, _default) do
    [_start, ending] = String.split(range, "-")
    ending |> String.trim() |> String.to_integer()
  rescue
    _ -> 0
  end
end
