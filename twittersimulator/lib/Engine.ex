defmodule Engine do
  use GenServer

  def init(engine_state) do
    state = %{}

    Utils.initialize_tables()
    {:ok, state}
  end

  def handle_call({:register_users, user_id}, _from, state) do
    result = Utils.register_users(user_id)
    {:reply, result, state}
  end

  def handle_cast({:login_user, user_id}, state) do
    # :ets.insert(:userLogIn, {user_id, true})
    # user has logged in
    # TODO: push all the tweets the user is subscribed to
    # do  receiveFeed on client
    Utils.login_user(user_id)
    {:noreply, state}
  end

  def handle_cast({:logout_user, user_id, state}) do
    Utils.logout_user(user_id)
    {:noreply, state}
  end

  def handle_cast({:handle_tweet, user_id, tweet_owner, tweet_content}, state) do
    # Once a user tweets, the engine should get the subscribers of the user and then extract the
    # hashtags and mentions, if there is hashtag, then insert the tweet into the table with that hashtag as key
    # if there is a mention, then get the user who is mentioned and add it to the mentions table
    # Also while sending the tweet to the subscriber, check if he is logged in using the loggedIn table, if yes, then send it.

    # Searching for hashtags or mentions
    # We can give the query processing time here, start the timer when the query has been received and calcuate the endtime when the tweet
    # has been sent to all the subscribers
    #IO.puts("Handle tweet")
    #IO.inspect(tweet_content)

    tweet =
      cond do
        :ets.member(:userTweets, user_id) ->
          [{_, tweets}] = :ets.lookup(:userTweets, user_id)
          tweets ++ [{tweet_owner, tweet_content}]

        true ->
          [{tweet_owner, tweet_content}]
      end

    Utils.insert_into_userTweets(user_id, tweet)
    # Utils.handle_tweet(user_id, tweet_content)
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, tweet_owner, tweet_content)

    mentions_list = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(mentions_list, tweet_owner, tweet_content)

    Utils.send_tweet_to_subscribers(user_id, {tweet_owner, tweet_content})

    {:noreply, state}
  end

  def handle_cast({:handle_retweet, user_id, tweet_owner, tweet_content}, state) do
    #IO.puts("Handle tweet")
    #IO.inspect(tweet_content)

    tweet =
      cond do
        :ets.member(:userTweets, user_id) ->
          [{_, tweets}] = :ets.lookup(:userTweets, user_id)
          tweets ++ [{tweet_owner, tweet_content}]

        true ->
          [{tweet_owner, tweet_content}]
      end

    :ets.insert(:userTweets, {user_id, tweet})
    Utils.send_tweet_to_subscribers(user_id, {tweet_owner, tweet_content})

    {:noreply, state}

  end

  # UserToSub_id is the one you want to follow, user_id is the one following
  def handle_cast({:subscribe_user, userToSubscibe_id, user_id}, state) do
    # Utils.subscribe_user(userToSubscibe_id, user_id)

    if(:ets.member(:users, userToSubscibe_id)) do
      [{userToSubscibe_id, followers}] = :ets.lookup(:users, userToSubscibe_id)
      if(length(followers)<=0 or !Enum.member?(followers, user_id)) do
          Utils.update_followers_list(userToSubscibe_id, user_id)
          Utils.update_following_list(userToSubscibe_id, user_id)
      end
    end
    {:noreply, state}
  end

  def handle_call({:search_hashtags, user_id, search_hashtags}, _from,state) do

    start_time = System.monotonic_time()
    IO.puts start_time
    tweets_for_hashtag = Utils.get_tweets_for_hashtag(search_hashtags)
    end_time = System.monotonic_time()
    IO.puts end_time
    IO.puts "Time taken to query a hashtag = #{end_time-start_time}"
    {:reply, tweets_for_hashtag,state}
  end

  def handle_cast({:search_mentions, user_id, search_mentions}, state) do
    tweets_for_mention = Utils.get_tweets_with_mentions(search_mentions)
    GenServer.cast(String.to_atom(to_string(user_id)), {:search_mention_reply, tweets_for_mention})

    {:noreply, state}
  end

  def handle_cast({:delete_user_account, user_id}, state) do
    Utils.delete_user(user_id)
    {:noreply, state}
  end

  def handle_call({:get_subscribed_tweets, user_id}, _from, state) do
    tweet_list = Utils.get_subscribed_tweets(user_id)
    {:reply, tweet_list, state}
  end

end



'''
// to select from a table with multiple keys
my_keys = [:a,:b]
iex >> :ets.select(table, (for key <- my_keys, do: {{key, :_}, [], [:"$_"]}))
[
  a: [{:banana, :orange, 10}, {:tomato, :potato, 6}],
  b: [{:car, :moto, 1}, {:plane, :heli, 60}]
]
'''
