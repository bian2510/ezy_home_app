defmodule EzyHomeAppWeb.PageController do
  use EzyHomeAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
