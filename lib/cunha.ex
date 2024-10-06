defmodule Cunha do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias HTTPoison

  @tmdb_api_key "<TOKEN>"
  @tmdb_base_url "https://api.themoviedb.org/3"

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do
      String.starts_with?(msg.content, "!cunha") ->
        Api.create_message(msg.channel_id, "Eae gostosa")

        String.starts_with?(msg.content, "!filme") ->
          handle_movie_command(msg)

        String.starts_with?(msg.content, "!serie") ->
          handle_serie_command(msg)

        true ->
          :ignore
    end
  end

  def handle_movie_command(msg) do
    case String.split(msg.content, " ", [parts: 2, trim: true]) do
        ["!filme"] ->
        Api.create_message(msg.channel_id, "Use o comando certo gostosa: !filme [nome do filme]")

        ["!filme", movie_name] -> search_movie(movie_name, msg.channel_id)

        :ignore
    end
  end

  def handle_serie_command(msg) do
    case String.split(msg.content, " ", [parts: 2, trim: true]) do
      ["!serie"] ->
        Api.create_message(msg.channel_id, "Use o comando certo gostosa: !serie [nome da serie]")

      ["!serie", serie_name] -> search_serie(serie_name, msg.channel_id)

      :ignore
    end
  end

  defp search_movie(movie_name, channel_id) do
    url = "#{@tmdb_base_url}/search/movie?api_key=#{@tmdb_api_key}&query=#{URI.encode(movie_name)}&language=pt-Br"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_movie_response(body, channel_id)

      {:error, _} ->
        Api.create_message(channel_id, "Erro ao buscar o filme. Tente novamente.")
    end
  end

  defp search_serie(serie_name, channel_id) do
    url = "#{@tmdb_base_url}/search/tv?api_key=#{@tmdb_api_key}&query=#{URI.encode(serie_name)}&language=pt-Br"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_serie_response(body, channel_id)

      {:error, _} ->
        Api.create_message(channel_id, "Erro ao buscar a série. Tente novamente.")
    end
  end

  defp parse_movie_response(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"results" => [first_movie | _]}} ->
        title = first_movie["title"]
        overview = first_movie["overview"]
        release_date = first_movie["release_date"]
        rating = first_movie["vote_average"]
        poster_path = first_movie["poster_path"]

        message = """
        **#{title}** (#{release_date})
        Nota: #{rating}/10
        #{overview}
        #{poster_url(poster_path)}
        """

        Api.create_message(channel_id, message)

      {:ok, %{"results" => []}} ->
        Api.create_message(channel_id, "Nenhum filme encontrado com esse nome.")

      _ ->
        Api.create_message(channel_id, "Erro ao processar a resposta.")
    end
  end

  defp parse_serie_response(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"results" => [first_series | _]}} ->
        name = first_series["name"]
        overview = first_series["overview"]
        first_air_date = first_series["first_air_date"]
        rating = first_series["vote_average"]
        poster_path = first_series["poster_path"]

        message = """
        **#{name}** (#{first_air_date})
        Nota: #{rating}/10
        #{overview}
        #{poster_url(poster_path)}
        """

        Api.create_message(channel_id, message)

      {:ok, %{"results" => []}} ->
        Api.create_message(channel_id, "Nenhuma série encontrada com esse nome.")

      _ ->
        Api.create_message(channel_id, "Erro ao processar a resposta.")
    end
  end

  defp poster_url(nil), do: ""
  defp poster_url(path), do: "https://image.tmdb.org/t/p/w500#{path}"

end
