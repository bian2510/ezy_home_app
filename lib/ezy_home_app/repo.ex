defmodule EzyHomeApp.Repo do
  use Ecto.Repo,
    otp_app: :ezy_home_app,
    adapter: Ecto.Adapters.Postgres
end
