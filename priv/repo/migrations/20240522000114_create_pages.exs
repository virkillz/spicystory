defmodule Eroticlone.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :page, :integer
      add :content, :text
      add :story_id, references(:stories, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:pages, [:story_id])
  end
end
