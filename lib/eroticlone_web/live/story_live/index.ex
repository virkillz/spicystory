defmodule EroticloneWeb.StoryLive.Index do
  use EroticloneWeb, :live_view

  alias Eroticlone.Content
  alias Eroticlone.Content.Story

  @impl true
  def mount(params, _session, socket) do
    stories = Content.list_stories(params)
    current_user = socket.assigns.current_user

    new_socket =
      socket
      |> assign(:page_title, "Listing Stories")
      |> assign(:conn, %{request_path: "/stories"})
      |> assign(:current_user, current_user)
      |> assign(:page, stories)
      |> stream(:stories, stories)

    {:ok, new_socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Story")
    |> assign(:story, Content.get_story!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Story")
    |> assign(:story, %Story{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Stories")
    |> assign(:story, nil)
  end

  @impl true
  def handle_info({EroticloneWeb.StoryLive.FormComponent, {:saved, story}}, socket) do
    {:noreply, stream_insert(socket, :stories, story)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    story = Content.get_story!(id)
    {:ok, _} = Content.delete_story(story)

    {:noreply, stream_delete(socket, :stories, story)}
  end
end
