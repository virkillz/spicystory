defmodule Ollama do
  @moduledoc """
  Documentation for `TryOpenai`.
  """

  @system_prompt "You are a helpful assistant. If you don't know the answer, you can ask for more information and tell me you don't know."

  @url "https://ollama.isengbeli.com/api/generate"
  # @model "codellama"

  # @url "http://localhost:11434/api/generate"
  # @model "lexifun"
  # @model "phi3"
  @model "dolphin-llama3"

  def get_models() do
    url = "https://ollama.isengbeli.com/api/tags"

    headers = [
      "content-type": "application/json"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000]

    HTTPoison.get(url, headers, options)
  end

  def run(prompt) do
    IO.inspect(prompt)

    url = @url

    headers = [
      "content-type": "application/json"
    ]

    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 50000, timeout: 20000]
    prompt = prompt_generate(prompt)
    body = Jason.encode!(prompt)

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"response" => response}} ->
            {:ok, response}

          other ->
            other
        end

      {:ok, %HTTPoison.Response{status_code: 422, body: body}} ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, inspect(reason)}

      error ->
        {:error, inspect(error)}
    end
  end

  def prompt_generate(prompt) do
    %{
      "model" => @model,
      "prompt" => prompt,
      "stream" => false
    }
  end

  def prompt_custom(prompt) do
    %{
      "model" => @model,
      "messages" => prompt,
      "stream" => false,
      "format" => "json"
    }
  end
end
