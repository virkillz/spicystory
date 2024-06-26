defmodule DrawThings do
  @moduledoc """
  Documentation for `TryOpenai`.
  """

  # @url "http://localhost:7860/sdapi/v1/txt2img"
  @url "https://ollama.isengbeli.com/sdapi/v1/txt2img"

  def draw_only(prompt) do
    url = @url

    headers = [
      "content-type": "application/json"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000, timeout: 20000]
    body = Jason.encode!(prompt)

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"images" => images}} ->
            {:ok, images |> List.first()}

          _other ->
            {:error, "Cannot create images"}
        end

      error ->
        IO.inspect(error)
        {:error, "Cannot create images"}
    end
  end

  def draw(prompt, story) do
    case draw_only(prompt) do
      {:ok, image} ->
        save_image(image, story.id)

      {:error, _} ->
        {:error, "Cannot create images"}
    end
  end

  def save_image(image, story_id) do
    location = Path.absname("priv/static/images/")
    file_name = Nanoid.generate() <> "image_#{story_id}.png"
    path = "#{location}/#{file_name}"

    case File.write(path, Base.decode64!(image)) |> IO.inspect() do
      :ok ->
        {:ok, file_name}

      _error ->
        {:error, "Cannot save image"}
    end
  end
end
