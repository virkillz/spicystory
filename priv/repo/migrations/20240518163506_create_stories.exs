defmodule Eroticlone.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :title, :string
      add :link, :string
      add :author, :string
      add :rating, :float
      add :content, :text
      add :status, :string
      add :category, :string
      add :tagline, :string
      add :image, :string
      add :fav, :integer
      add :metadata, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:stories, [:link])
  end
end
