defmodule Cunha do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias HTTPoison

  @tmdb_api_key ""
  @tmdb_base_url "https://api.themoviedb.org/3"

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do
      String.starts_with?(msg.content, "!cunha") ->
        Api.create_message(msg.channel_id, "Eae gostosa")

      String.starts_with?(msg.content, "!ajuda") ->
        send_help_message(msg.channel_id)

      String.starts_with?(msg.content, "!filme") ->
        handle_movie_command(msg)

      String.starts_with?(msg.content, "!serie") ->
        handle_serie_command(msg)

      String.starts_with?(msg.content, "!recomendar") ->
        ask_for_recommendation_type(msg)

      String.starts_with?(msg.content, "!trailer") ->
        handle_trailer_command(msg)

      true ->
        :ignore
    end
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------

  def send_help_message(channel_id) do
    help_message = """
    **Comandos disponíveis:**
    - `!cunha`: Mensagem de saudação
    - `!ajuda`: Exibe esta lista de comandos
    - `!filme [nome do filme]`: Busca informações sobre um filme
    - `!serie [nome da série]`: Busca informações sobre uma série
    - `!trailer [nome do filme]`: Busca o trailer do filme
    - `!recomendar [filme ou serie] [gênero (opcional)]`: Recomenda um filme ou série aleatório.
      **Gêneros disponíveis para recomendação:**
      - **Filmes**: ação, aventura, comédia, drama, terror, romance, ficção científica, animação, crime, documentário, família, fantasia, história, música, mistério, guerra, faroeste, thriller
      - **Séries**: ação, aventura, comédia, drama, terror, romance, ficção científica, animação, crime, documentário, família, fantasia, mistério, realidade, guerra e política, faroeste, talk show, kids
    """
    Api.create_message(channel_id, help_message)
end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------

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

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------

  def ask_for_recommendation_type(msg) do
    case String.split(msg.content, " ", [parts: 3, trim: true]) do
      ["!recomendar"] ->
        Api.create_message(msg.channel_id, "Use o comando certo: !recomendar [filme/serie] [gênero ou 'random']")

      ["!recomendar", "filme", genre] ->
        recommend_movie(msg.channel_id, genre)

      ["!recomendar", "filme"] ->
        recommend_movie(msg.channel_id, "random")

      ["!recomendar", "serie", genre] ->
        recommend_serie(msg.channel_id, genre)

      ["!recomendar", "serie"] ->
        recommend_serie(msg.channel_id, "random")

      _ ->
        Api.create_message(msg.channel_id, "Comando inválido. Use o formato: !recomendar [filme/serie] [gênero ou 'random']")
    end
  end

  def recommend_movie(channel_id, "random") do
    url = "#{@tmdb_base_url}/movie/popular?api_key=#{@tmdb_api_key}&language=pt-BR&page=#{:rand.uniform(500)}"
    fetch_and_parse_recommendation(url, channel_id, :movie)
  end

  def recommend_movie(channel_id, genre) do
    genre_id = get_genre_id(genre, :movie)

    if genre_id do
      url = "#{@tmdb_base_url}/discover/movie?api_key=#{@tmdb_api_key}&with_genres=#{genre_id}&language=pt-BR&page=#{:rand.uniform(500)}"
      fetch_and_parse_recommendation(url, channel_id, :movie)
    else
      Api.create_message(channel_id, "Gênero inválido ou não encontrado.")
    end
  end

  def recommend_serie(channel_id, "random") do
    url = "#{@tmdb_base_url}/tv/popular?api_key=#{@tmdb_api_key}&language=pt-BR&page=#{:rand.uniform(500)}"
    fetch_and_parse_recommendation(url, channel_id, :serie)
  end

  def recommend_serie(channel_id, genre) do
    genre_id = get_genre_id(genre, :serie)

    if genre_id do
      url = "#{@tmdb_base_url}/discover/tv?api_key=#{@tmdb_api_key}&with_genres=#{genre_id}&language=pt-BR&page=#{:rand.uniform(500)}"
      fetch_and_parse_recommendation(url, channel_id, :serie)
    else
      Api.create_message(channel_id, "Gênero inválido ou não encontrado.")
    end
  end

  defp get_genre_id(genre, :movie) do
    movie_genres = %{
      "ação" => 28,
      "aventura" => 12,
      "comédia" => 35,
      "drama" => 18,
      "terror" => 27,
      "romance" => 10749,
      "ficção científica" => 878,
      "animação" => 16,
      "crime" => 80,
      "documentário" => 99,
      "família" => 10751,
      "fantasia" => 14,
      "história" => 36,
      "música" => 10402,
      "mistério" => 9648,
      "guerra" => 10752,
      "faroeste" => 37,
      "thriller" => 53
    }

    Map.get(movie_genres, String.downcase(genre))
end

  defp get_genre_id(genre, :serie) do
    serie_genres = %{
      "ação" => 10759,
      "aventura" => 10759,
      "comédia" => 35,
      "drama" => 18,
      "terror" => 9648,
      "romance" => 10749,
      "ficção científica" => 10765,
      "animação" => 16,
      "crime" => 80,
      "documentário" => 99,
      "família" => 10751,
      "fantasia" => 10765,
      "mistério" => 9648,
      "realidade" => 10764,
      "guerra e política" => 10768,
      "faroeste" => 37,
      "talk show" => 10767,
      "kids" => 10762
    }

    Map.get(serie_genres, String.downcase(genre))
end


  defp fetch_and_parse_recommendation(url, channel_id, :movie) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_recommendation_response_movie(body, channel_id)
      {:error, _} ->
        Api.create_message(channel_id, "Ops! Não consegui pegar uma recomendação no momento.")
    end
  end

  defp fetch_and_parse_recommendation(url, channel_id, :serie) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_recommendation_response_serie(body, channel_id)
      {:error, _} ->
        Api.create_message(channel_id, "Ops! Não consegui pegar uma recomendação no momento.")
    end
  end

  defp parse_recommendation_response_movie(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"results" => [first_movie | _]}} ->
        title = first_movie["title"]
        overview = first_movie["overview"]
        release_date = first_movie["release_date"]
        rating = first_movie["vote_average"]
        poster_path = first_movie["poster_path"]

        teaser = "🎬 Você não pode perder este filme: **#{title}**! 🍿"
        curiosity = "Curiosidade: A nota média dele é #{rating}/10! Que tal assistir hoje? 😉"
        fun_fact = "Lembre-se: cada filme é uma nova aventura! 🌟"
        message = """
        #{teaser}
        **Lançamento:** #{release_date}
        **Nota:** #{rating}/10
        #{overview}
        #{poster_url(poster_path)}
        #{curiosity}
        #{fun_fact}
        """

        Api.create_message(channel_id, message)

      {:ok, %{"results" => []}} ->
        Api.create_message(channel_id, "Nenhum filme encontrado! Tente novamente! 🎥")

      _ ->
        Api.create_message(channel_id, "Erro ao processar a resposta. Tente novamente. ❌")
    end
  end

  defp parse_recommendation_response_serie(body, channel_id) do
    case Jason.decode(body) do
      {:ok, %{"results" => [first_series | _]}} ->
        title = first_series["name"]
        overview = first_series["overview"]
        first_air_date = first_series["first_air_date"]
        rating = first_series["vote_average"]
        poster_path = first_series["poster_path"]

        teaser = "📺 Você não pode perder esta série: **#{title}**! 🍿"
        curiosity = "Curiosidade: A nota média dela é #{rating}/10! Que tal assistir hoje? 😉"
        fun_fact = "Lembre-se: cada série é uma nova aventura! 🌟"
        message = """
        #{teaser}
        **Lançamento:** #{first_air_date}
        **Nota:** #{rating}/10
        #{overview}
        #{poster_url(poster_path)}
        #{curiosity}
        #{fun_fact}
        """

        Api.create_message(channel_id, message)

      {:ok, %{"results" => []}} ->
        Api.create_message(channel_id, "Nenhuma série encontrada! Tente novamente! 📺")

      _ ->
        Api.create_message(channel_id, "Erro ao processar a resposta. Tente novamente. ❌")
    end
  end

  # ----------------------------------------------------------------------
  # ----------------------------------------------------------------------

def handle_trailer_command(msg) do
  case String.split(msg.content, " ", [parts: 2, trim: true]) do
    ["!trailer"] ->
      Api.create_message(msg.channel_id, "Use o comando certo gostosa: !trailer [nome do filme]")

    ["!trailer", movie_name] ->
      search_trailer(movie_name, msg.channel_id)

    :ignore
  end
end

defp search_trailer(movie_name, channel_id) do
  url = "#{@tmdb_base_url}/search/movie?api_key=#{@tmdb_api_key}&query=#{URI.encode(movie_name)}&language=pt-BR"

  case HTTPoison.get(url) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
      case Jason.decode(body) do
        {:ok, %{"results" => [first_movie | _]}} ->
          movie_id = first_movie["id"]
          fetch_trailer(movie_id, channel_id)

        {:ok, %{"results" => []}} ->
          Api.create_message(channel_id, "Nenhum filme encontrado com esse nome.")

        _ ->
          Api.create_message(channel_id, "Erro ao processar a resposta.")
      end

    {:error, _} ->
      Api.create_message(channel_id, "Erro ao buscar o filme. Tente novamente.")
  end
end

defp fetch_trailer(movie_id, channel_id) do
  url = "#{@tmdb_base_url}/movie/#{movie_id}/videos?api_key=#{@tmdb_api_key}&language=pt-BR"

  case HTTPoison.get(url) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
      case Jason.decode(body) do
        {:ok, %{"results" => trailers}} ->
          trailer = Enum.find(trailers, fn video -> video["type"] == "Trailer" && video["site"] == "YouTube" end)

          if trailer do
            trailer_url = "https://www.youtube.com/watch?v=#{trailer["key"]}"
            Api.create_message(channel_id, "Aqui está o trailer: #{trailer_url}")
          else
            Api.create_message(channel_id, "Trailer não encontrado.")
          end

        _ ->
          Api.create_message(channel_id, "Erro ao processar a resposta.")
      end

    {:error, _} ->
      Api.create_message(channel_id, "Erro ao buscar o trailer. Tente novamente.")
  end
end

  defp poster_url(nil), do: ""
  defp poster_url(path), do: "https://image.tmdb.org/t/p/w500#{path}"

end
