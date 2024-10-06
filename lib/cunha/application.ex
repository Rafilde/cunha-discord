defmodule Cunha.Application do

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Cunha
    ]
    opts = [strategy: :one_for_one, name: Cunha.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
