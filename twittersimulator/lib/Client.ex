defmodule Client do
  def init(client_state) do
    state = %{
      "hashtag_list" => Enum.at(client_state, 0)
      # {}"users_list" => Enum.at(client_state,0)
    }

    IO.puts("creating client")
    {:ok, state}
  end

  def handle_cast({:register, user_id}, state) do
    IO.puts("Inside register")
    GenServer.cast(String.to_atom("engine"), {:register_users, user_id})
    {:noreply, state}
  end

  def handle_cast({:subscribe, user_id, num_users}, state) do
    IO.puts("Inside subscribe")
    userToSub = Enum.random(1..num_users)
    # {:ok, String.to_atom("engine")} = Map.fetch(state, "engine_pid")
    GenServer.cast(String.to_atom("engine"), {:subscribe_user, userToSub, user_id})
    {:noreply, state}
  end

  def handle_cast({:send_tweets, user_id, num_users}, state) do
    IO.puts("Inside send tweets")
    {:ok, hashtag_list} = Map.fetch(state, "hashtag_list")
    # IO.inspect(engine_name)
    # n = Enum.random(1..num_users)
    tweet_content = prepare_tweet(user_id, num_users, hashtag_list)
    # IO.puts("Tweet content is #{tweet_content}")
    GenServer.cast(String.to_atom("engine"), {:handle_tweet, user_id, tweet_content})
    {:noreply, state}
  end

  def prepare_tweet(user_id, num_users, hashtag_list) do
    # IO.puts("Inside prepare_tweet")
    list1 = [1, 2, 3, 4]
    random_tweet = Enum.random(list1)

    tweet =
      cond do
        random_tweet == 1 ->
          # pick a hashtag randomly and insert it into the tweet content
          no_hashtags = Enum.random(1..2)

          cond do
            no_hashtags == 1 ->
              #  n = Enum.random(1..10)
              hashtag = Enum.random(hashtag_list)
              "This is a string with  hashtag #{hashtag}"

            no_hashtags == 2 ->
              # n1 = Enum.random(1..10)
              hashtag1 = Enum.random(hashtag_list)
              # n2 = Enum.random(1..10)
              hashtag2 = Enum.random(hashtag_list)
              "This is a string with  hashtag #{hashtag1} and #{hashtag2}"
          end

        # We are limiting the number of hashtags in a tweet to 2
        random_tweet == 2 ->
          no_mentions = Enum.random(1..2)

          cond do
            no_mentions == 1 ->
              user = Enum.random(1..num_users)
              mention = "@#{user}"
              "This is a string with mention id #{mention}"

            no_mentions == 2 ->
              user1 = Enum.random(1..num_users)
              mention1 = "@#{user1}"
              user2 = Enum.random(1..num_users)
              mention2 = "@#{user2}"
              "This is a string with mention ids #{mention1} and #{mention2}"
          end

        random_tweet == 3 ->
          # n1 = Enum.random(1..10)
          hashtag1 = Enum.random(hashtag_list)
          user1 = Enum.random(1..num_users)
          mention1 = "@#{user1}"
          "This is a string with one mention #{mention1} and one hashtag #{hashtag1}"

        random_tweet == 4 ->
          "This is just a normal tweet with no mentions or hashtags"
      end
  end

  # If anyone we subscribed to tweets, receive it
  def handle_cast({:receiveTweet, user_id, tweet_content}, state) do
    IO.puts("receiving tweets")
    # IO.puts(tweet_content)
    # TODO: might want to retweet.
    # maintain a list of tweets using Map.update(a,1,[],fn list -> list ++ [tweet] end)
    # %{1 => [23]}
    retweet_list = [0, 1]
    retweet_yes = Enum.random(retweet_list)

    cond do
      retweet_yes == 1 ->
        GenServer.cast(String.to_atom(to_string(user_id)), {:reTweet, user_id, tweet_content})

      true ->
        :ok
    end

    {:noreply, state}
  end

  # this happens when a user logs in
  def handle_cast({:receiveFeed, tweets_content}, state) do
    IO.puts("receiving feed")
    {:noreply, state}
  end

  def handle_cast({:reTweet, user_id, retweet_content}, state) do
    IO.puts("retweeting")
    # {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(String.to_atom("engine"), {:handle_tweet, user_id, retweet_content})
    {:noreply, state}
  end

  # Search for tweets with a given hashtag
  # GenServer callback to query for tweets with given hashtags
  def handle_cast({:searchHashtags, user_id}, state) do
    IO.puts("Client will search for a hashtag")
    {:ok, hashtag_list} = Map.fetch(state, "hashtag_list")
    decide_hashtags = [1, 2]
    pick_num_hastags = Enum.random(decide_hashtags)
    hashtags_to_search = []
    # TODO Again here we are limiting the number of hashtags a user can search for to 2
    hashtags =
      cond do
        pick_num_hastags == 1 ->
          # n1 = Enum.random(1..10)
          hashtag1 = Enum.random(hashtag_list)
          hashtags_to_search ++ [hashtag1]

        pick_num_hastags == 2 ->
          hashtag1 = Enum.random(hashtag_list)
          hashtag2 = Enum.random(hashtag_list)
          hashtags_to_search ++ [hashtag1] ++ [hashtag2]
      end

    GenServer.cast(String.to_atom("engine"), {:search_hashtags, user_id, hashtags})
    {:noreply, state}
  end

  def handle_cast({:search_hashtag_reply, tweets_for_hashtag}, state) do
    IO.puts("receiving tweets with given hashtags")
    IO.puts(tweets_for_hashtag)
    {:noreply, state}
  end

  def handle_cast({:searchMentions, user_id, mentions}, state) do
    IO.puts("Client will search for a mention")
    # {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(String.to_atom("engine"), {:search_mentions, user_id, mentions})
    {:noreply, state}
  end

  def handle_cast({:search_mention_reply, tweets_for_mention}, state) do
    IO.puts("Receiving tweets for the mention")
    IO.puts(tweets_for_mention)
    {:noreply, state}
  end
end
