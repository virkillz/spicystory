defmodule EroticloneWeb.PageController do
  use EroticloneWeb, :controller

  alias Eroticlone.Content

  def show(conn, %{"slug" => slug}) do
    story = Content.get_story_by_slug(slug)
    next_story = Content.get_random_story()

    if is_nil(story) do
      conn |> put_status(404) |> text("404")
    else
      render(conn, "home.html", story: story, next_url: next_story.slug, layout: false)
    end
  end

  def home(conn, _params) do
    story = Content.get_random_story()

    redirect(conn, to: ~p"/show/#{story.slug}")
  end

  def dashboard(conn, _params) do
    all = Content.count_all_stories()
    finished = Content.count_finished_stories()
    images = Content.count_story_with_images()

    percentage = finished / all * 100

    data = %{
      all: all,
      finished: finished,
      image_count: images,
      percentage: Float.round(percentage, 4)
    }

    render(conn, "dashboard.html", data: data)
  end

  def published_index(conn, params) do
    stories = Content.list_bookmarked_stories(params)

    render(conn, "published.html", stories: stories)
  end

  def author_index(conn, %{"author" => author}) do
    stories = Content.list_stories_by_author(author)

    render(conn, "author.html", stories: stories)
  end

  def randomize(conn, _params) do
    story = Content.get_random_finished_story()

    redirect(conn, to: ~p"/stories/#{story.id}")
  end

  def random(conn, _params) do
    stories = Content.list_random_stories(12)

    render(conn, "random.html", stories: stories)
  end

  def get_remaining_pages(conn, %{"id" => id}) do
    story = Content.get_story!(id)

    if story.pages != [] do
      conn
      |> put_flash(:error, "Story already has pages")
      |> redirect(to: "/stories/#{id}")
    else
      Eroticlone.get_next_pages(story)

      conn
      |> put_flash(:info, "Pages generated")
      |> redirect(to: "/stories/#{id}")
    end
  end

  def post_story(conn, story_params) do
    case Content.create_story(story_params) do
      {:ok, story} ->
        conn |> json(%{id: story.id})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> put_status(422) |> json(%{errors: changeset.errors})
    end
  end
end
