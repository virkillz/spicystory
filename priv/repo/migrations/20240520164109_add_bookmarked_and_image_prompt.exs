defmodule Eroticlone.Repo.Migrations.AddBookmarkedAndImagePrompt do
  use Ecto.Migration

  def change do
    alter table(:stories) do
      add :is_bookmarked, :boolean, default: false
      add :image_prompt, :text
    end
  end
end
