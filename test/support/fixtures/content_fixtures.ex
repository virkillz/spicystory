defmodule Eroticlone.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Eroticlone.Content` context.
  """

  @doc """
  Generate a unique story link.
  """
  def unique_story_link, do: "some link#{System.unique_integer([:positive])}"

  @doc """
  Generate a story.
  """
  def story_fixture(attrs \\ %{}) do
    {:ok, story} =
      attrs
      |> Enum.into(%{
        author: "some author",
        category: "some category",
        content: "some content",
        link: unique_story_link(),
        rating: 120.5,
        status: "some status",
        title: "some title"
      })
      |> Eroticlone.Content.create_story()

    story
  end

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        content: "some content",
        page: 42
      })
      |> Eroticlone.Content.create_page()

    page
  end
end
