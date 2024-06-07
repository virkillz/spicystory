defmodule Eroticlone.Remote do
  alias Eroticlone.Content

  @remote_url "http://34.128.83.247/"
  # @remote_url "http://localhost:4000/"

  @moduledoc """
  Eroticlone keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def get_remote_url() do
    @remote_url
  end

  def list_stories_with_empty_image() do
    headers = [
      "content-type": "application/json"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000]

    case HTTPoison.get(@remote_url <> "api/stories/no-image", headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode(body)

      _ ->
        {:error, "Cannot get stories"}
    end
  end

  # Eroticlone.generate_remote_image("a-serving-girls-tale")
  def generate_remote_image(slug) do
    headers = [
      "content-type": "application/json"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000]

    IO.inspect("got called")

    case HTTPoison.get(@remote_url <> "api/stories/#{slug}", headers, options) |> IO.inspect() do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        story = Jason.decode!(body)

        if is_nil(story["image_prompt"]) do
          {:error, "No image prompt found"}
        else
          prompt = %{
            prompt: story["image_prompt"],
            width: 384,
            height: 512
          }

          case DrawThings.draw_only(prompt) do
            {:ok, file_raw} ->
              HTTPoison.post(
                @remote_url <> "api/stories/#{slug}",
                Jason.encode!(%{"story" => %{"image_raw" => file_raw}}),
                headers,
                options
              )

            {:error, _} ->
              {:error, "Cannot create images"}
          end
        end

      _ ->
        {:error, "Cannot get story"}
    end
  end

  # note
  # last sync : 54404
  # another sync: 140_000 - 150_000 (loving wives) done
  # another sync: 160_000 - 170_000 (mature) otw
  # another sync: 170_000 - 180_000 (humor)
  # another sync: 190_000 - 200_000 (romance)
  # Eroticlone.sync_all_stories(41112, 50000)
  def sync_all_stories(start, finish) do
    start..finish
    |> Enum.each(fn id ->
      IO.inspect("Processing #{id}")

      case post_story(id) do
        {:ok, _} ->
          IO.inspect("Success")

        {:error, _} ->
          IO.inspect("Error")
      end
    end)
  end

  def post_story(story_id) do
    story = Content.get_story(story_id)

    if is_nil(story) do
      {:error, "Story not found"}
    else
      attrs = %{
        "link" => story.link,
        "author" => story.author,
        "rating" => story.rating,
        "status" => story.status,
        "image" => story.image,
        "category" => story.category,
        "is_bookmarked" => story.is_bookmarked,
        "image_prompt" => story.image_prompt,
        "content" => story.content,
        "title" => story.title,
        "tagline" => story.tagline,
        "fav" => story.fav,
        "metadata" => story.metadata,
        "is_read" => story.is_read,
        "is_approved" => story.is_approved,
        "slug" => story.slug
      }

      url = @remote_url <> "api/stories"

      headers = [
        "content-type": "application/json"
      ]

      options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000, timeout: 20000]
      body = Jason.encode!(attrs)

      case HTTPoison.post(url, body, headers, options) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          IO.inspect(body)
          {:ok, body}

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect(reason)
          {:error, reason}

        error ->
          IO.inspect(error)
          {:error, "Cannot create story"}
      end
    end
  end
end
