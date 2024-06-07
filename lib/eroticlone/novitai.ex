defmodule Novitai do
  @token "e5848388-fc3d-44e0-aa70-4825f43a4795"
  @url "https://api.novita.ai/v3/openai/v1/chat/completions"
  @model "lzlv_70b"

  def run(prompt) do
    url = @url

    headers = [
      Authorization: "Bearer #{@token}",
      Accept: "Application/json; Charset=utf-8",
      "content-type": "application/json"
    ]

    params = %{
      "model" => @model,
      "messages" => [
        %{
          "role" => "system",
          "content" => "You are a helpful assistant."
        },
        %{
          "role" => "user",
          "content" => prompt
        }
      ],
      "stream" => false,
      "function_call" => "none"
    }

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000, timeout: 20000]
    body = Jason.encode!(params)

    case HTTPoison.post(url, body, headers, options) |> IO.inspect() do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => content}}]}} ->
            {:ok, content}

          other ->
            other
        end

      {:ok, %HTTPoison.Response{status_code: 422, body: body}} ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "Not found"

      {:error, %HTTPoison.Error{reason: reason}} ->
        reason

      error ->
        error
    end
  end
end
