defmodule Client do
  def init(client_state) do
    state = %{
      "hashtag_list" => Enum.at(client_state, 0),
      "user_id" => Enum.at(client_state, 1)

      # {}"users_list" => Enum.at(client_state,0)
    }

    IO.puts("creating client")
    {:ok, state}
  end

  def handle_cast({:register}, state) do
    IO.puts("Inside register")

    GenServer.call(String.to_atom("engine"), {:register_users, state["user_id"]})
    {:noreply, state}
  end

  def handle_cast({:subscribe, num_users}, state) do
    IO.puts("Inside subscribe")
    numOfUsersToSubcribe = Enum.random(1..num_users)
    Enum.each(1..numOfUsersToSubcribe, fn n->
      userToSub = Enum.random(1..num_users)
      if(userToSub!=state["user_id"]) do
        GenServer.cast(String.to_atom("engine"), {:subscribe_user, userToSub, state["user_id"]})
      end
    end)
    {:noreply, state}
  end

  def handle_cast({:send_tweets, num_users}, state) do
    IO.puts("Inside send tweets")
    {:ok, hashtag_list} = Map.fetch(state, "hashtag_list")
    # IO.inspect(engine_name)
    # n = Enum.random(1..num_users)
    tweet_content = prepare_tweet(state["user_id"], num_users, hashtag_list)
    # IO.puts("Tweet content is #{tweet_content}")
    GenServer.cast(
      String.to_atom("engine"),
      {:handle_tweet, state["user_id"], state["user_id"], tweet_content}
    )

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

    retweet_yes = Enum.random(0..1)

    cond do
      retweet_yes == 1 ->
        GenServer.cast(
          String.to_atom(to_string(user_id)),
          {:reTweet, state["user_id"], tweet_content}
        )

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

  def handle_cast({:reTweet, user_id, retweet}, state) do
    # if a user has already retweeted or is the owner don't retweet.

    IO.puts("retweetinggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg")
    {tweet_owner, tweet_content} = retweet

    my_tweets = if :ets.member(:userTweets, user_id) do
      [{user_id, my_tweets}] = :ets.lookup(:userTweets, user_id)
      my_tweets
    else
      []
    end

    if tweet_owner != user_id and length(my_tweets)>0 and !Enum.member?(my_tweets, {tweet_owner, tweet_content}) do
      IO.puts(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
      IO.inspect("#{user_id} retweeting #{tweet_content} by #{tweet_owner}")
      IO.inspect(my_tweets)
      GenServer.cast(String.to_atom("engine"), {:handle_retweet, user_id, tweet_owner, tweet_content})
    end
    {:noreply, state}

  end

  # Search for tweets with a given hashtag
  # GenServer callback to query for tweets with given hashtags
  def handle_cast({:searchHashtags}, state) do
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

    GenServer.cast(String.to_atom("engine"), {:search_hashtags, state["user_id"], hashtags})
    {:noreply, state}
  end

  def handle_cast({:search_hashtag_reply, tweets_for_hashtag}, state) do
    IO.puts("receiving tweets with given hashtags")
    IO.puts(tweets_for_hashtag)
    {:noreply, state}
  end

  def handle_cast({:searchMentions, mentions}, state) do
    IO.puts("Client will search for a mention")
    # {:ok, engine_name} = Map.fetch(state, "engine_pid")
    GenServer.cast(String.to_atom("engine"), {:search_mentions, state["user_id"], mentions})
    {:noreply, state}
  end

  def handle_cast({:search_mention_reply, tweets_for_mention}, state) do
    IO.puts("Receiving tweets for the mention")
    IO.puts(tweets_for_mention)
    {:noreply, state}
  end

  def handle_cast({:delete_account}, state) do
    IO.puts "User is deleting the account"
    GenServer.cast(String.to_atom("engine"), {:delete_user_account, state["user_id"]})
  end

end
