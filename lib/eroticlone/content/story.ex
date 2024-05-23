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
end
