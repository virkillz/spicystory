defmodule EroticloneWeb.PageLive.FormComponent do
  use EroticloneWeb, :live_component

  alias Eroticlone.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage page records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="page-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:page]} type="number" label="Page" />
        <.input field={@form[:content]} type="text" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Page</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{page: page} = assigns, socket) do
    changeset = Content.change_page(page)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"page" => page_params}, socket) do
    changeset =
      socket.assigns.page
      |> Content.change_page(page_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"page" => page_params}, socket) do
    save_page(socket, socket.assigns.action, page_params)
  end

  defp save_page(socket, :edit, page_params) do
    case Content.update_page(socket.assigns.page, page_params) do
      {:ok, page} ->
        notify_parent({:saved, page})

        {:noreply,
         socket
         |> put_flash(:info, "Page updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_page(socket, :new, page_params) do
    case Content.create_page(page_params) do
      {:ok, page} ->
        notify_parent({:saved, page})

        {:noreply,
         socket
         |> put_flash(:info, "Page created successfully")
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
