defmodule Engine do
  use GenServer

  def init(engine_state) do
    state = %{}
    # userID (key), list of followers (value)
    # :ets.new(:users, [:set, :public, :named_table])
    # # userID (key), list of users being followed by user
    # :ets.new(:following, [:set, :public, :named_table])
    # # :ets.new(:followers, [:set, :public, :named_table])
    #
    # :ets.new(:tweets, [
    #   :set,
    #   :public,
    #   :named_table,
    #   {:read_concurrency, true},
    #   {:write_concurrency, true}
    # ])
    #
    # :ets.new(:hashtags, [
    #   :set,
    #   :public,
    #   :named_table,
    #   {:read_concurrency, true},
    #   {:write_concurrency, true}
    # ])
    #
    # :ets.new(:mentionIds, [
    #   :set,
    #   :public,
    #   :named_table,
    #   {:read_concurrency, true},
    #   {:write_concurrency, true}
    # ])
    #
    # :ets.new(:userLogIn, [:set, :public, :named_table])

    # Enum.each(1..10, fn hashtag ->
    #   hashtag_id = "#h#{hashtag}"
    #   :ets.insert_new(:hashtags, {hashtag_id, []})
    # end)
    Utils.initialize_tables()
    {:ok, state}
  end

  def handle_cast({:register_users, user_id}, state) do
    # IO.puts("Inside engine and registering users")
    # :ets.insert_new(:users, {user_id, []})
    # mention_id = "@#{user_id}"
    # # IO.puts("Mention id is #{mention_id}")
    # :ets.insert_new(:userLogIn, {user_id, true})
    # :ets.insert_new(:mentionIds, {mention_id, []})
    # # TODO Decide on this
    # :ets.insert_new(:userLogIn, {user_id, true})
    Utils.register_users(user_id)
    {:noreply, state}
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

  def handle_cast({:handle_tweet, user_id, tweet_content, tweet_owner}, state) do
    # Once a user tweets, the engine should get the subscribers of the user and then extract the
    # hashtags and mentions, if there is hashtag, then insert the tweet into the table with that hashtag as key
    # if there is a mention, then get the user who is mentioned and add it to the mentions table
    # Also while sending the tweet to the subscriber, check if he is logged in using the loggedIn table, if yes, then send it.

    # Searching for hashtags or mentions
    # We can give the query processing time here, start the timer when the query has been received and calcuate the endtime when the tweet
    # has been sent to all the subscribers
    IO.puts("Handle tweet")
    IO.inspect(tweet_content)

    tweet =
      cond do
        :ets.member(:userTweets, user_id) ->
          [{_, tweets}] = :ets.lookup(:userTweets, user_id)
          tweets ++ [{tweet_owner, tweet_content}]

        true ->
          [{tweet_owner, tweet_content}]
      end

    :ets.insert(:userTweets, {user_id, tweet})
    # Utils.handle_tweet(user_id, tweet_content)
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, tweet)

    mentions_list = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(mentions_list, tweet)

    Utils.send_tweet_to_subscribers(user_id, {tweet_owner, tweet_content})

    {:noreply, state}
  end

  # UserToSub_id is the one you want to follow, user_id is the one following
  def handle_cast({:subscribe_user, userToSubscibe_id, user_id}, state) do
    # Utils.subscribe_user(userToSubscibe_id, user_id)
    Utils.update_followers_list(userToSubscibe_id, user_id)
    Utils.update_following_list(userToSubscibe_id, user_id)
    {:noreply, state}
  end

  def handle_cast({:search_hashtags, user_id, search_hashtags}, state) do
    tweets_for_hashtag = Utils.get_tweets_for_hashtag(search_hashtags)
    GenServer.cast(user_id, {:search_hashtag_reply, tweets_for_hashtag})

    {:noreply, state}
  end

  def handle_cast({:search_mentions, user_id, search_mentions}, state) do
    tweets_for_mention = Utils.get_tweets_with_mentions(search_mentions)
    GenServer.cast(user_id, {:search_mention_reply, tweets_for_mention})

    {:noreply, state}
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
