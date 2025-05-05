defmodule EroticloneWeb.PageController do
  use EroticloneWeb, :controller

  alias Eroticlone.Content

  def show(conn, %{"slug" => slug}) do
    story = Content.get_story_by_slug(slug)
    next_story = Content.get_random_story()
    pages = story.pages |> Enum.map(& &1.content)

    time_to_read =
      [story.content | pages]
      |> Enum.join(" ")
      |> String.split(" ")
      |> Enum.count()
      |> div(200)

    if is_nil(story) do
      conn |> put_status(404) |> text("404")
    else
      render(conn, "home.html",
        story: story,
        next_url: next_story.slug,
        time_to_read: time_to_read,
        layout: false
      )
    end
  end

  def public_bookmark(conn, params) do
    stories = Content.list_bookmarked_stories(params)
    render(conn, "public_bookmark.html", stories: stories, layout: false)
  end

  def bookmark(conn, %{"slug" => slug}) do
    story = Content.get_story_by_slug(slug)
    Content.bookmark_story(story)

    redirect(conn, to: ~p"/show/#{story.slug}")
  end

  def unbookmark(conn, %{"slug" => slug}) do
    story = Content.get_story_by_slug(slug)
    Content.unbookmark_story(story)

    redirect(conn, to: ~p"/show/#{story.slug}")
  end

  def get_story_by_id(conn, %{"id" => id}) do
    story = Content.get_story!(id)

    if is_nil(story) do
      conn |> put_status(404) |> text("404")
    else
      json =
        Map.from_struct(story)
        |> Map.delete(:__meta__)
        |> Map.delete(:__struct__)
        |> Map.delete(:pages)

      json(conn, json)
    end
  end

  def home(conn, _params) do
    story = Content.get_random_story()

    redirect(conn, to: ~p"/show/#{story.slug}")
  end

  def remote_index(conn, _params) do
    stories = Eroticlone.Remote.list_stories_with_empty_image()

    case stories do
      {:error, _} ->
        conn |> put_flash(:error, "Cannot get stories") |> redirect(to: "/")

      {:ok, stories} ->
        render(conn, "remote.html", stories: stories)
    end
  end

  def generate_remote_image(conn, %{"slug" => slug}) do
    IO.inspect(slug)

    case Eroticlone.Remote.generate_remote_image(slug) do
      {:error, _} ->
        conn |> put_flash(:error, "Cannot create images") |> redirect(to: "/remote/stories")

      {:ok, _} ->
        conn |> put_flash(:info, "Image created") |> redirect(to: "/remote/stories")
    end
  end

  def get_no_images(conn, _params) do
    stories =
      Content.list_stories_with_empty_image(20)
      |> Enum.map(fn x ->
        %{
          id: x.id,
          title: x.title,
          slug: x.slug,
          image_prompt: x.image_prompt
        }
      end)

    json(conn, stories)
  end

  def dashboard(conn, _params) do
    all = Content.count_all_stories()
    images = Content.count_story_with_images()
    finished = Content.count_finished_stories()

    percentage = finished / all * 100

    data = %{
      all: all,
      finished: finished,
      image_count: images,
      percentage: Float.round(percentage, 4)
    }

    render(conn, "dashboard.html", data: data, layout: false)
  end

  def process(conn, %{"id" => id}) do
    story = Content.get_story!(id)

    case Eroticlone.process(story) do
      {:ok, _} ->
        conn |> put_flash(:info, "Story processed") |> redirect(to: "/stories/#{id}")

      {:error, _} ->
        conn |> put_flash(:error, "Cannot process story") |> redirect(to: "/stories/#{id}")
    end
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

  def get_story(conn, %{"slug" => slug}) do
    case Content.get_story_by_slug(slug) do
      nil ->
        conn |> put_status(404) |> text("404")

      story ->
        json = %{
          id: story.id,
          title: story.title,
          image: story.image,
          is_bookmarked: story.is_bookmarked,
          image_prompt: story.image_prompt
        }

        json(conn, json)
    end
  end

  def update_story(conn, %{"slug" => slug, "story" => story_params}) do
    case Content.get_story_by_slug(slug) do
      nil ->
        conn |> put_status(404) |> text("404")

      story ->
        case Content.update_story_remotely(story, story_params) do
          {:ok, story} ->
            conn |> json(%{id: story.id})

          {:error, %Ecto.Changeset{} = changeset} ->
            conn |> put_status(422) |> json(%{errors: "Failed to update story"})
        end
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
