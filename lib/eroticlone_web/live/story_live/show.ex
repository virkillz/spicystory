defmodule EroticloneWeb.StoryLive.Show do
  use EroticloneWeb, :live_view

  alias Eroticlone.Content

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok, socket |> assign(:current_user, current_user)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    story = Content.get_story!(id) |> IO.inspect()

    display_story =
      if is_nil(story.content) do
        case Eroticlone.process(story) do
          {:ok, new_story} ->
            new_story

          {:error, _} ->
            story
        end
      else
        story
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:story, display_story)}
  end

  @impl true
  def handle_event("generate_image", _params, socket) do
    story = socket.assigns.story

    case Eroticlone.generate_female_image(story) do
      {:ok, story} ->
        {:noreply, socket |> assign(:story, story)}

      {:error, error} ->
        {:noreply, socket |> put_flash(:error, "Failed to generate image")}
    end
  end

  def handle_event("approve_story", _params, socket) do
    IO.inspect("got called")
    story = socket.assigns.story
    {:ok, new_story} = Content.update_story(story, %{is_read: true, is_approved: true})

    {:noreply, socket |> assign(:story, new_story)}
  end

  def handle_event("reject_story", _params, socket) do
    story = socket.assigns.story
    {:ok, new_story} = Content.update_story(story, %{is_read: true, is_approved: false})

    {:noreply, socket |> assign(:story, new_story)}
  end

  def handle_event("generate_image_prompt", _params, socket) do
    story = socket.assigns.story

    case Eroticlone.generate_female_image_prompt(story) do
      {:ok, story} ->
        {:noreply, socket |> assign(:story, story)}

      {:error, error} ->
        {:noreply, socket |> put_flash(:error, error)}
    end
  end

  def handle_event("delete", _unsigned_params, socket) do
    story = socket.assigns.story
    {:ok, _} = Content.delete_story(story)

    {:noreply, redirect(socket, to: "/stories")}
  end

  def handle_event("bookmark", _params, socket) do
    story = socket.assigns.story
    {:ok, story} = Content.update_story(story, %{is_bookmarked: true})

    {:noreply, socket |> assign(:story, story)}
  end

  def handle_event("unbookmark", _params, socket) do
    story = socket.assigns.story
    {:ok, story} = Content.update_story(story, %{is_bookmarked: false})

    {:noreply, socket |> assign(:story, story)}
  end

  defp page_title(:show), do: "Show Story"
  defp page_title(:edit), do: "Edit Story"
end
