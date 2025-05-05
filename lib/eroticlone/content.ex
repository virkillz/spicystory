defmodule Eroticlone.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias Eroticlone.Repo

  alias Eroticlone.Content.Story

  @doc """
  Returns the list of stories.

  ## Examples

      iex> list_stories()
      [%Story{}, ...]

  """
  def list_stories do
    Repo.all(Story)
  end

  def list_stories(params) do
    query =
      from s in Story,
        order_by: s.id

    Repo.paginate(query, params)
  end

  def list_unstarted_stories(limit) do
    query =
      from s in Story,
        where: s.status == "unstarted",
        limit: ^limit,
        order_by: fragment("RANDOM()")

    Repo.all(query)
  end

  def list_stories_by_author(author) do
    query =
      from s in Story,
        where: s.author == ^author

    Repo.all(query)
  end

  def list_bookmarked_stories(params) do
    query =
      from s in Story,
        where: s.is_bookmarked == true,
        preload: [:pages],
        order_by: [desc: s.updated_at]

    Repo.paginate(query, params)
  end

  def list_stories_with_empty_slug(limit) do
    query =
      from s in Story,
        where: is_nil(s.slug),
        limit: ^limit

    Repo.all(query)
  end

  def list_stories_with_empty_image(limit) do
    query =
      from s in Story,
        where: is_nil(s.image),
        where: s.is_bookmarked == true,
        limit: ^limit

    Repo.all(query)
  end

  # story = Eroticlone.Content.get_story!(10)
  # Eroticlone.Content.create_slug(story)
  def update_slug(story) do
    slug = story.link |> String.split("s/") |> List.last() |> String.downcase()
    update_story(story, %{slug: slug})
  end

  def count_unstarted_stories do
    query =
      from s in Story,
        where: s.status == "unstarted"

    Repo.aggregate(query, :count, :id)
  end

  def count_bookmarked_stories do
    query =
      from s in Story,
        where: s.is_bookmarked == true

    Repo.aggregate(query, :count, :id)
  end

  def get_story_by_slug(slug) do
    query =
      from s in Story,
        where: s.slug == ^slug,
        preload: [:pages]

    Repo.one(query)
  end

  def count_finished_stories do
    query =
      from s in Story,
        where: s.status == "finished"

    Repo.aggregate(query, :count, :id)
  end

  def count_all_stories do
    query = from(s in Story)

    Repo.aggregate(query, :count, :id)
  end

  def count_story_with_images() do
    query =
      from s in Story,
        where: not is_nil(s.image)

    Repo.aggregate(query, :count, :id)
  end

  # Eroticlone.Content.scrap_progress()
  def scrap_progress() do
    count_finished_stories() / count_all_stories() * 100
  end

  @doc """
  Gets a single story.

  Raises `Ecto.NoResultsError` if the Story does not exist.

  ## Examples

      iex> get_story!(123)
      %Story{}

      iex> get_story!(456)
      ** (Ecto.NoResultsError)

  """
  def get_story!(id), do: Repo.get!(Story, id) |> Repo.preload(:pages)

  def get_story(id), do: Repo.get(Story, id) |> Repo.preload(:pages)

  def get_random_story do
    query =
      from s in Story,
        limit: 1,
        # where: s.is_bookmarked == true,
        where: s.status == "finished",
        order_by: fragment("RANDOM()")

    Repo.one(query)
  end

  def get_random_story_empty_image do
    query =
      from s in Story,
        limit: 1,
        where: is_nil(s.image_prompt),
        order_by: fragment("RANDOM()")

    Repo.one(query)
  end

  def bookmark_story(story) do
    update_story(story, %{is_bookmarked: true})
  end

  def unbookmark_story(story) do
    update_story(story, %{is_bookmarked: false})
  end

  def get_random_finished_story do
    query =
      from s in Story,
        limit: 1,
        where: s.status == "finished",
        order_by: fragment("RANDOM()")

    Repo.one(query)
  end

  def list_random_stories(limit) do
    query =
      from s in Story,
        limit: ^limit,
        # where: s.status == "finished",
        order_by: fragment("RANDOM()")

    Repo.all(query)
  end

  def list_stories_with_unfinished_images do
    query =
      from s in Story,
        where: not is_nil(s.image_prompt),
        where: is_nil(s.image)

    Repo.all(query)
  end

  @doc """
  Creates a story.

  ## Examples

      iex> create_story(%{field: value})
      {:ok, %Story{}}

      iex> create_story(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_story(attrs \\ %{}) do
    %Story{}
    |> Story.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a story.

  ## Examples

      iex> update_story(story, %{field: new_value})
      {:ok, %Story{}}

      iex> update_story(story, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_story(%Story{} = story, attrs) do
    story
    |> Story.changeset(attrs)
    |> Repo.update()
  end

  def update_story_remotely(%Story{} = story, attrs) do
    story
    |> Story.changeset_update_remote(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a story.

  ## Examples

      iex> delete_story(story)
      {:ok, %Story{}}

      iex> delete_story(story)
      {:error, %Ecto.Changeset{}}

  """
  def delete_story(%Story{} = story) do
    Repo.delete(story)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking story changes.

  ## Examples

      iex> change_story(story)
      %Ecto.Changeset{data: %Story{}}

  """
  def change_story(%Story{} = story, attrs \\ %{}) do
    Story.changeset(story, attrs)
  end

  alias Eroticlone.Content.Page

  @doc """
  Returns the list of pages.

  ## Examples

      iex> list_pages()
      [%Page{}, ...]

  """
  def list_pages do
    Repo.all(Page)
  end

  @doc """
  Gets a single page.

  Raises `Ecto.NoResultsError` if the Page does not exist.

  ## Examples

      iex> get_page!(123)
      %Page{}

      iex> get_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_page!(id), do: Repo.get!(Page, id)

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page.

  ## Examples

      iex> update_page(page, %{field: new_value})
      {:ok, %Page{}}

      iex> update_page(page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a page.

  ## Examples

      iex> delete_page(page)
      {:ok, %Page{}}

      iex> delete_page(page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.

  ## Examples

      iex> change_page(page)
      %Ecto.Changeset{data: %Page{}}

  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end
end
