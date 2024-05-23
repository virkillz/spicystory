defmodule DrawThings do
  @moduledoc """
  Documentation for `TryOpenai`.
  """

  @url "http://localhost:7860/sdapi/v1/txt2img"

  def draw(prompt, story) do
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
            images |> List.first() |> save_image(story)

          _other ->
            {:error, "Cannot create images"}
        end

      error ->
        IO.inspect(error)
        {:error, "Cannot create images"}
    end
  end

  def save_image(image, story) do
    location = Path.absname("priv/static/images/")
    file_name = Nanoid.generate() <> "image_#{story.id}.png"
    path = "#{location}/#{file_name}"

    File.write(path, Base.decode64!(image))

    {:ok, file_name}
  end
end
