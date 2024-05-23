defmodule EroticloneWeb.StoryLive.FormComponent do
  use EroticloneWeb, :live_component

  alias Eroticlone.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage story records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="story-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:link]} type="text" label="Link" />
        <.input field={@form[:author]} type="text" label="Author" />
        <.input field={@form[:rating]} type="number" label="Rating" step="any" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:image]} type="text" label="Image" />
        <.input field={@form[:category]} type="text" label="Category" />
        <.input field={@form[:is_bookmarked]} type="checkbox" label="Bookmarked" />
        <.input field={@form[:image_prompt]} type="textarea" label="Custom Image Prompt" />
        <.input field={@form[:content]} type="textarea" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Story</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{story: story} = assigns, socket) do
    changeset = Content.change_story(story)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"story" => story_params}, socket) do
    changeset =
      socket.assigns.story
      |> Content.change_story(story_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"story" => story_params}, socket) do
    save_story(socket, socket.assigns.action, story_params)
  end

  defp save_story(socket, :edit, story_params) do
    case Content.update_story(socket.assigns.story, story_params) do
      {:ok, story} ->
        notify_parent({:saved, story})

        {:noreply,
         socket
         |> put_flash(:info, "Story updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_story(socket, :new, story_params) do
    case Content.create_story(story_params) do
      {:ok, story} ->
        notify_parent({:saved, story})

        {:noreply,
         socket
         |> put_flash(:info, "Story created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
