defmodule Cunha do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias HTTPoison

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do
      String.starts_with?(msg.content, "!cunha") ->
        Api.create_message(msg.channel_id, "Eae gostosa")
      String.starts_with?(msg.content, "!ppt") ->
        handle_ppt(msg)
      String.starts_with?(msg.content, "!piada") ->
        handle_piada(msg)
      true -> :ignore
    end
  end

  defp handle_ppt(msg) do
    case String.split(msg.content, " ", [parts: 2, trim: true]) do
      ["!ppt"] ->
        Api.create_message(msg.channel_id, ":x: Comando !ppt inválido, use !ppt [pedra | papel | tesoura]")
      ["!ppt", valor] ->
        get_ppt_game_result(valor, msg)
      _ ->
        :ignore
    end
  end

  defp get_ppt_game_result(valor, msg) do
    if Enum.member?(["pedra", "papel", "tesoura"], valor) do
      bot_valor = Enum.random(["pedra", "papel", "tesoura"])

      cond do
        valor == bot_valor ->
          Api.create_message(msg.channel_id, "Eu escolhi #{bot_valor} e houve um empate! :nerd:")
        valor == "pedra" && bot_valor == "tesoura" ->
          Api.create_message(msg.channel_id, "Eu escolhi #{bot_valor} e você ganhou! :sob:")
        valor == "papel" && bot_valor == "pedra" ->
          Api.create_message(msg.channel_id, "Eu escolhi #{bot_valor} e você ganhou! :sob:")
        valor == "tesoura" && bot_valor == "papel" ->
          Api.create_message(msg.channel_id, "Eu escolhi #{bot_valor} e você ganhou! :sob:")
        true ->
          Api.create_message(msg.channel_id, "Eu escolhi #{bot_valor} e ganhei! :sunglasses:")
      end
    else
      Api.create_message(msg.channel_id, ":x: Comando !ppt inválido, use !ppt [pedra | papel | tesoura]")
    end
  end

  defp handle_piada(msg) do
    case get_piada() do
      {:ok, piada} ->
        Api.create_message(msg.channel_id, piada)
      {:error, reason} ->
        Api.create_message(msg.channel_id, "Desculpe, não consegui encontrar uma piada agora. :cry:")
    end
  end

  defp get_piada() do
    case HTTPoison.get("https://v2.jokeapi.dev/joke/Any") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        handle_piada_response(body)
      {:error, _} ->
        {:error, "Falha ao buscar piada."}
    end
  end

  defp handle_piada_response(body) do
    %{"setup" => setup, "delivery" => delivery} = Jason.decode!(body)

    if setup != nil and delivery != nil do
      {:ok, "#{setup} - #{delivery}"}
    else
      %{"joke" => joke} = Jason.decode!(body)
      {:ok, joke}
    end
  end
end
