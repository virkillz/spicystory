defmodule Eroticlone.Content.Story do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stories" do
    field :author, :string
    field :category, :string
    field :content, :string
    field :link, :string
    field :rating, :float
    field :status, :string, default: "unstarted"
    field :title, :string
    field :tagline, :string
    field :image, :string
    field :fav, :integer
    field :metadata, :string
    field :is_bookmarked, :boolean, default: false
    field :image_prompt, :string
    field :is_read, :boolean, default: false
    field :is_approved, :boolean, default: false
    field :slug, :string
    field :image_raw, :string, virtual: true

    timestamps(type: :utc_datetime)

    has_many :pages, Eroticlone.Content.Page
  end

  @doc false
  def changeset(story, attrs) do
    story
    |> cast(attrs, [
      :title,
      :link,
      :author,
      :rating,
      :content,
      :status,
      :category,
      :tagline,
      :image,
      :fav,
      :metadata,
      :is_bookmarked,
      :image_prompt,
      :is_read,
      :is_approved,
      :slug
    ])
    |> validate_required([:link])
    |> unique_constraint(:link)
  end

  def changeset_update_remote(story, attrs) do
    story
    |> cast(attrs, [
      :image,
      :is_bookmarked,
      :image_raw
    ])
    |> process_image()
  end

  defp process_image(changeset) do
    image_raw = get_field(changeset, :image_raw)
    id = get_field(changeset, :id)

    IO.inspect(id)

    case DrawThings.save_image(image_raw, id) do
      {:ok, image_filename} ->
        put_change(changeset, :image, image_filename)

      {:error, _} ->
        changeset |> add_error(:image, "Failed to save image")
    end
  end
end
