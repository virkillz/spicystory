defmodule Eroticlone.Content.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :content, :string
    field :page, :integer
    field :story_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:page, :content, :story_id])
    |> validate_required([:page, :content])
  end
end
