defmodule Eroticlone do
  alias Eroticlone.Content

  @remote_url "http://34.128.83.247/"

  @moduledoc """
  Eroticlone keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def scrap() do
    finished = Content.count_finished_stories()
    count_all = Content.count_all_stories()

    remaining = count_all - finished

    Cachex.put(:my_cache, "count_progress", finished)

    IO.inspect("Processing #{remaining} stories")

    Content.list_unstarted_stories(remaining)
    |> Enum.each(fn story ->
      IO.inspect("Processing #{story.id}")

      case process(story) do
        {:ok, _} ->
          {:ok, finished} = Cachex.incr(:my_cache, "count_progress", 1)

          percentage = finished * 100 / count_all

          IO.inspect("Progress: #{Float.round(percentage, 4)}%")

        {:error, _} ->
          IO.inspect("Error processing #{story.id}")
      end
    end)
  end

  # Eroticlone.process_unstarted(1)
  def process_unstarted(limit \\ 10) do
    Content.list_unstarted_stories(limit)
    |> Enum.each(fn story ->
      IO.inspect("Processing #{story.id}")
      process(story)
    end)
  end

  def process(story) do
    case HTTPoison.get(story.link, [], timeout: 10_000, recv_timeout: 20_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        metadata = extract_metadata(body)

        story_attrs = %{
          "author" => extract_author(body),
          "category" => extract_category(body),
          "content" => extract_content(body),
          "rating" => validate_ratings(metadata.rate),
          "title" => extract_title(body),
          "tagline" => extract_tagline(body),
          "fav" => validate_fav(metadata.fav),
          "metadata" => Jason.encode!(metadata),
          "status" => "finished"
        }

        Content.update_story(story, story_attrs)

      {:ok, %HTTPoison.Response{status_code: _code}} ->
        Content.delete_story(story)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Content.delete_story(story)
    end
  end

  def validate_fav(0) do
    0
  end

  def validate_fav(fav) do
    if String.contains?(fav, "k") do
      0
    else
      fav
    end
  end

  def validate_ratings(0) do
    0.0
  end

  def validate_ratings(rating) do
    if String.contains?(rating, "k") do
      0.0
    else
      rating
    end
  end

  def extract_content(html) do
    # {"div", [{"class", "aa_ht"}], [{"div", [], content}]} =
    html
    |> Floki.parse_document!()
    |> Floki.find(".aa_ht")
    |> List.first()
    |> Floki.raw_html()

    # content |> Enum.map(&Floki.text/1) |> Enum.join("\n\n")
  end

  def extract_title(html) do
    Floki.parse_document!(html) |> Floki.find(".headline") |> Floki.text()
  end

  def extract_metadata(html) do
    max_page = extract_max_page(html)

    case Floki.parse_document!(html)
         |> Floki.find(".aT_H")
         |> Enum.map(fn x -> Floki.text(x) end) do
      [rate, view, fav, comments] ->
        %{
          rate: rate,
          view: view,
          fav: fav,
          comments: comments,
          max_page: max_page
        }

      [rate, view, fav] ->
        %{
          rate: rate,
          view: view,
          fav: fav,
          comments: 0,
          max_page: max_page
        }

      [view, fav] ->
        %{
          rate: 0,
          view: view,
          fav: fav,
          comments: 0,
          max_page: max_page
        }

      [view] ->
        %{
          rate: 0,
          view: view,
          fav: 0,
          comments: 0,
          max_page: max_page
        }

      [] ->
        %{
          rate: 0,
          view: 0,
          fav: 0,
          comments: 0,
          max_page: max_page
        }

      other ->
        IO.inspect(other)
    end
  end

  def extract_author(html) do
    Floki.parse_document!(html) |> Floki.find(".y_eU") |> List.first() |> Floki.text()
  end

  def extract_tagline(html) do
    Floki.parse_document!(html) |> Floki.find(".bn_B") |> List.first() |> Floki.text()
  end

  def extract_max_page(html) do
    Floki.parse_document!(html) |> Floki.find(".l_bJ") |> List.last() |> Floki.text()
  end

  def extract_category(html) do
    Floki.parse_document!(html) |> Floki.find(".h_aZ") |> List.last() |> Floki.text()
  end

  # Eroticlone.save_link_from_category("adult-humor", 1, 22)
  def save_link_from_category(category_id, min_page, max_page) do
    Enum.each(min_page..max_page, fn page ->
      url = "https://www.literotica.com/c/#{category_id}/#{page}-page"

      case get_all_link(url) do
        "404" ->
          IO.puts("404")

        links ->
          Enum.each(links, fn x ->
            %{
              "title" => extract_link_title(x),
              "link" => extract_link_url(x),
              "author" => extract_link_author(x),
              "rating" => extract_link_rating(x),
              "tagline" => extract_link_tagline(x)
            }
            |> Content.create_story()
            |> IO.inspect()
          end)
      end

      # Process.sleep(1000)
    end)
  end

  defp extract_link_author(floki_doc) do
    floki_doc
    |> Floki.find(".b-sli-author")
    |> Floki.find("a")
    |> Floki.text()
  end

  defp extract_link_title(floki_doc) do
    floki_doc |> Floki.find(".r-34i") |> Floki.text()
  end

  defp extract_link_rating(floki_doc) do
    floki_doc |> Floki.find(".b-sli-rating") |> Floki.text()
  end

  defp extract_link_tagline(floki_doc) do
    floki_doc |> Floki.find(".b-sli-description") |> Floki.text() |> String.replace(" — ", "")
  end

  defp extract_link_url(floki_doc) do
    floki_doc |> Floki.find(".r-34i") |> Floki.attribute("href") |> List.first()
  end

  def generate_female_image_prompt(story) do
    if is_nil(story.content) do
      {:error, "No content found"}
    else
      length = String.length(story.content) |> div(3)

      first_half_story = String.slice(story.content, 0..length)

      ollama_prompt = """
      Give me the detail physical description of the female character and appropriate location description in the story below:

      #{first_half_story}

      """

      case Ollama.run(ollama_prompt) do
        {:ok, response} ->
          Content.update_story(story, %{"image_prompt" => response})

        {:error, _} ->
          {:error, "Cannot generate image prompt"}
      end
    end
  end

  # Eroticlone.generate_remote_image("the-erotic-adventures-of-superman")
  def generate_remote_image(slug) do
    case HTTPoison.get(@remote_url <> "api/stories/#{slug}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        story = Jason.decode!(body)

        if is_nil(story["image_prompt"]) do
          {:error, "No image prompt found"}
        else
          prompt = %{
            prompt: story.image_prompt,
            width: 384,
            height: 512
          }

          case DrawThings.draw_only(prompt) do
            {:ok, file_raw} ->
              HTTPoison.post(
                @remote_url <> "api/stories/#{slug}",
                Jason.encode!(%{"image_raw" => file_raw})
              )

            {:error, _} ->
              {:error, "Cannot create images"}
          end
        end

      _ ->
        {:error, "Cannot get story"}
    end
  end

  def generate_female_image(story) do
    if is_nil(story.image_prompt) do
      {:error, "No image prompt found"}
    else
      prompt = %{
        prompt: story.image_prompt,
        width: 576,
        height: 768
      }

      case DrawThings.draw(prompt, story) do
        {:ok, file_name} ->
          Content.update_story(story, %{"image" => file_name})

        {:error, _} ->
          {:error, "Cannot create images"}
      end
    end
  end

  def get_all_link(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Floki.parse_document!()
        |> Floki.find(".w-34t")

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "404"

      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end

  def sanitize(text) do
    text
    |> String.replace(~r/<li>/, "\\g{1}- ", global: true)
    |> String.replace(
      ~r/<\/?\s?br>|<\/\s?p>|<\/\s?li>|<\/\s?div>|<\/\s?h.>/,
      "\\g{1}\n\r",
      global: true
    )

    # |> PhoenixHtmlSanitizer.Helpers.sanitize(:strip_tags)
  end

  def sanitize_string(string) do
    String.replace(string, ~r/[^a-zA-Z0-9 :.,]/, "")
  end

  def get_next_pages(story) do
    metadata = Jason.decode!(story.metadata)

    if not is_nil(metadata["max_page"]) do
      max_page = String.to_integer(metadata["max_page"])

      targets = if max_page > 2, do: 2..max_page, else: [2]

      Enum.each(targets, fn page ->
        url = story.link <> "?page=#{page}"

        case HTTPoison.get(url, [], timeout: 10_000, recv_timeout: 20_000) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            page_attrs = %{
              "story_id" => story.id,
              "page" => page,
              "content" => extract_content(body)
            }

            Content.create_page(page_attrs)

          other ->
            IO.inspect(other, label: "Cannot get next pages")
            {:error, "Cannot get next pages"}
        end
      end)
    end
  end

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

  # Eroticlone.story_to_md(3)
  def story_to_md(story_id) do
    story = Content.get_story(story_id)

    if is_nil(story) do
      {:error, "Story not found"}
    else
      {:ok, parsed} = Floki.parse_document(story.content)

      [{"div", [{"class", "aa_ht"}], [{"div", [], content}]}] = parsed

      result =
        content
        |> Enum.map(&parse_line/1)
        |> Enum.map(fn x ->
          """
          #{x}



          """
        end)
        |> Enum.join("")

      new_content = """
      # #{story.title}


      *#{story.tagline}*


      #{result}


      """

      File.write("story_#{story_id}.md", new_content)
    end
  end

  defp parse_line(line) do
    case line do
      {"p", [], [text]} ->
        Floki.text(line)

      {"p", [], [text, {"br", [], []}]} ->
        text <> "<br />"

      {"p", [], _other} ->
        Floki.text(line)

        # other ->
        #   IO.inspect(other, label: "anomaly detected")
    end
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

      url = "http://34.128.83.247/api/stories"

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
