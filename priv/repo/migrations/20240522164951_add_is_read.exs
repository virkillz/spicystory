defmodule Eroticlone.Repo.Migrations.AddIsRead do
  use Ecto.Migration

  def change do
    alter table(:stories) do
      add :is_read, :boolean
      add :is_approved, :boolean
    end
  end
end
