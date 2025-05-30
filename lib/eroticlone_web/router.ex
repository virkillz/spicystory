defmodule EroticloneWeb.Router do
  use EroticloneWeb, :router

  import EroticloneWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EroticloneWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EroticloneWeb do
    pipe_through :browser

    get "/show/:slug", PageController, :show
    get "/show/:slug/bookmark", PageController, :bookmark
    get "/show/:slug/unbookmark", PageController, :unbookmark
    get "/", PageController, :home
    get "/public_bookmark", PageController, :public_bookmark
    get "/randomize", PageController, :randomize
    get "/dashboard", PageController, :dashboard
    get "/stories/:id/fetch_pages", PageController, :get_remaining_pages
  end

  scope "/api", EroticloneWeb do
    pipe_through :api

    get "/stories/:id", PageController, :get_story_by_id
    get "/stories/no-image", PageController, :get_no_images
    get "/stories/:slug", PageController, :get_story
    post "/stories", PageController, :post_story
    post "/stories/:slug", PageController, :update_story
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:eroticlone, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EroticloneWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", EroticloneWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{EroticloneWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", EroticloneWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/random", PageController, :random
    get "/published", PageController, :published_index
    get "/authors/:author", PageController, :author_index
    get "/remote/stories", PageController, :remote_index
    get "/generate-remote/:slug", PageController, :generate_remote_image

    live_session :require_authenticated_user,
      on_mount: [{EroticloneWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      get "/stories/:id/process", PageController, :process

      live "/stories", StoryLive.Index, :index
      live "/stories/new", StoryLive.Index, :new
      live "/stories/:id/edit", StoryLive.Index, :edit

      live "/stories/:id", StoryLive.Show, :show
      live "/stories/:id/show/edit", StoryLive.Show, :edit

      live "/pages", PageLive.Index, :index
      live "/pages/new", PageLive.Index, :new
      live "/pages/:id/edit", PageLive.Index, :edit

      live "/pages/:id", PageLive.Show, :show
      live "/pages/:id/show/edit", PageLive.Show, :edit
    end
  end

  scope "/", EroticloneWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{EroticloneWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
