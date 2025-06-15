# Spreader

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Environment variables

Create a `.env` file at the project root (you can start from `.env.example`) and set the following:

```
GOOGLE_CLIENT_ID=<your-client-id>.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=<your-client-secret>
SECRET_KEY_BASE=$(mix phx.gen.secret)
DATABASE_URL=ecto://USER:PASS@localhost/spreader_dev
```

Load them for local dev (macOS/Linux):
```bash
source .env
mix phx.server
```

Be sure to add the redirect URI `http://localhost:4000/auth/google/callback` to your Google OAuth credentials, and the production URI when deploying.


Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
