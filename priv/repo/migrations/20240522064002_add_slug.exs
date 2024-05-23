defmodule Eroticlone.Repo.Migrations.AddSlug do
  use Ecto.Migration

  def change do
    alter table(:stories) do
      add :slug, :string
    end

    create unique_index(:stories, [:slug])
  end
end
