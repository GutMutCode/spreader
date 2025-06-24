defmodule SpreaderWeb.YouTubeUploadLive do
  @moduledoc """
  Simple UI for uploading a video to YouTube.

  * Displays a file input (accepts common video formats).
  * Lets the user enter title and description.
  * Streams the file to a temporary location via LiveView `allow_upload/3` and
    passes the path to `Spreader.YouTube.Uploader.upload/2`.
  * Shows success or failure message after upload.
  """

  use SpreaderWeb, :live_view
  alias Spreader.YouTube.Uploader

  @max_mb 1024 # 1 GB upload limit (adjust as needed)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:video,
       accept: ~w(.mp4 .mov .webm),
       max_entries: 1,
       max_file_size: @max_mb * 1_048_576
     )
     |> assign(:status, nil)
     |> assign(:title, "")
     |> assign(:description, "")}
  end

  @impl true
  def handle_event("validate", %{"title" => t, "description" => d}, socket) do
    {:noreply, assign(socket, title: t, description: d)}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "You must be logged in." )}
  end

  def handle_event("save", _params, socket) do
    %{assigns: %{current_user: user, title: title, description: desc}} = socket

    # Persist uploaded entry to a temp path
    entries = consume_uploaded_entries(socket, :video, fn %{path: path}, _ -> {:ok, path} end)

    case entries do
      [path] ->
        case Uploader.upload(user, filepath: path, title: title, description: desc) do
          {:ok, video_id} ->
            {:noreply,
             socket
             |> put_flash(:info, "Uploaded successfully! YouTube ID: #{video_id}")
             |> assign(:status, :ok)}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Upload failed: #{inspect(reason)}")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Please choose a video file.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-lg py-8">
      <h2 class="text-xl font-semibold mb-4">Upload Video to YouTube</h2>

      <.form for={%{}} phx-change="validate" phx-submit="save" class="space-y-4">
        <div class="mb-4">
          <.live_file_input upload={@uploads.video} />
        </div>

        <div class="mb-4">
          <label class="block mb-1">Title</label>
          <input type="text" name="title" value={@title} class="w-full border rounded px-2 py-1" />
        </div>

        <div class="mb-4">
          <label class="block mb-1">Description</label>
          <textarea name="description" rows="4" class="w-full border rounded px-2 py-1"><%= @description %></textarea>
        </div>

        <button type="submit" class="bg-blue-600 text-white px-4 py-2 rounded">Upload</button>
      </.form>

      <%= if @status == :ok do %>
        <p class="mt-4 text-green-600">Upload finished. Check your YouTube Studio.</p>
      <% end %>
    </div>
    """
  end
end
