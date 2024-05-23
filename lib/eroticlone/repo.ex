defmodule Eroticlone.Repo do
  use Ecto.Repo,
    otp_app: :eroticlone,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10, max_page_size: 50
end
