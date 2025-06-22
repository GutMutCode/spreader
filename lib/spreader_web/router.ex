defmodule SpreaderWeb.Router do
  use SpreaderWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug SpreaderWeb.AuthPlug
    plug Ueberauth
    plug SpreaderWeb.LocalePlug
    plug :put_root_layout, html: {SpreaderWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpreaderWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/youtube/upload", YouTubeUploadLive

    # Legal pages (public)
    get "/terms-of-service/:locale", TermsController, :show
    get "/privacy/:locale", PrivacyController, :show
  end

  scope "/auth", SpreaderWeb do
    pipe_through :browser

    get "/logout", AuthController, :logout
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpreaderWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:spreader, :dev_routes) do
    # gmc test route (internal)
    scope "/", SpreaderWeb do
      pipe_through :browser
      get "/gmc/terms/:locale", TermsController, :show
      get "/gmc/privacy/:locale", PrivacyController, :show
    end
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SpreaderWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
