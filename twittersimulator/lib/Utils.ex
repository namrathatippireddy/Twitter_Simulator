defmodule Utils do
  def initialize_tables() do
    :ets.new(:users, [:set, :public, :named_table])
    # userID (key), list of users being followed by user
    :ets.new(:following, [:set, :public, :named_table])
    # :ets.new(:followers, [:set, :public, :named_table])

    :ets.new(:userTweets, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      #{:write_concurrency, true}
    ])

    :ets.new(:hashtags, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:mentionIds, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(:userLogIn, [:set, :public, :named_table])
  end

  def register_users(user_id) do
    IO.puts("Inside engine and registering users")
    :ets.insert_new(:users, {user_id, []})
    # IO.puts("Mention id is #{mention_id}")
    :ets.insert_new(:userLogIn, {user_id, true})
  end

  def login_user(user_id) do
    :ets.insert(:userLogIn, {user_id, true})
  end

  def logout_user(user_id) do
    :ets.insert(:userLogIn, {user_id, false})
  end

  def insert_into_hashtagTable(list_of_hashtags, tweet_owner, tweet_content) do
    IO.inspect(list_of_hashtags)

    if(length(list_of_hashtags) > 0) do
      IO.puts("handling tweet #{list_of_hashtags}")

      Enum.each(list_of_hashtags, fn each_ht ->
        # IO.inspect(">>>>>>>>>>>>>>>>>>>>>>>>>> #{each_ht} ")

        ht_tweet =
          cond do
            :ets.member(:hashtags, each_ht) ->
              # IO.puts("hashtagggggggggggggggggggggggggggggggggggggggg #{each_ht}")
              [{_, tweets_for_ht}] = :ets.lookup(:hashtags, each_ht)
              tweets_for_ht ++ [{tweet_owner, tweet_content}]

            true ->
              # IO.puts("nooooooooooooooooooooooooooooooooooooooo ")
              [{tweet_owner, tweet_content}]
          end

        :ets.insert(:hashtags, {each_ht, ht_tweet})
        # IO.puts("Insertion complete")
        # a = :ets.lookup(:hashtags, "#h123")
        # IO.inspect(a)
      end)
    end
  end

  def insert_into_mentionsTable(mentions_list, tweet_owner, tweet_content) do
    if(length(mentions_list) > 0) do
      Enum.each(mentions_list, fn each_mention ->
        mention_tweet =
          cond do
            :ets.member(:mentionIds, each_mention) ->
              [{_, tweets_for_mention}] = :ets.lookup(:mentionIds, each_mention)
              tweets_for_mention ++ [{tweet_owner, tweet_content}]

            true ->
              [{tweet_owner, tweet_content}]
          end

        :ets.insert(:mentionIds, {each_mention, mention_tweet})
      end)
    end
  end

  def send_tweet_to_subscribers(user_id, tweet_content) do
    # get the subscribers for the given user_id and forward the tweet
    if :ets.member(:users, user_id) do
      [{_, subscriber_list}] = :ets.lookup(:users, user_id)
      # IO.inspect(subscriber_list)

      Enum.each(subscriber_list, fn subscriber ->
        # IO.puts("subscriber is ")
        # IO.inspect(subscriber)
        [{_, loggedIn}] = :ets.lookup(:userLogIn, subscriber)

        if(loggedIn) do
          GenServer.cast(
            String.to_atom(to_string(subscriber)),
            {:receiveTweet, subscriber, tweet_content}
          )
        end
      end)
    end
  end

  def get_hashtags(tweet_content) do
    list_of_hts1 = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet_content)
    IO.inspect(list_of_hts1)

    list_of_hts =
      if length(list_of_hts1) != 0 do
        Enum.reduce(list_of_hts1, [], fn hts, acc -> acc ++ [Enum.at(hts, 0)] end)
      else
        []
      end

    list_of_hts
  end

  def get_mentions(tweet_content) do
    list_of_mentions1 = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet_content)
    IO.inspect(list_of_mentions1)

    list_of_mentions =
      if length(list_of_mentions1) != 0 do
        Enum.reduce(list_of_mentions1, [], fn mentions, acc -> acc ++ [Enum.at(mentions, 0)] end)
      else
        []
      end

    list_of_mentions
  end

  def update_followers_list(userToSubscibe_id, user_id) do
    # we are updating the followers list of UserToSub_id
    followers_list = get_followers(userToSubscibe_id, user_id)
    :ets.insert(:users, {userToSubscibe_id, followers_list})
  end

  def update_following_list(userToSubscibe_id, user_id) do
    # we also update the following table of the present user who called this function
    subscribed_list = get_following(userToSubscibe_id, user_id)
    :ets.insert(:following, {user_id, subscribed_list})
  end

  def get_followers(userToSubscibe_id, user_id) do
    followers =
      cond do
        :ets.member(:users, userToSubscibe_id) ->
          [{userToSubscibe_id, followers}] = :ets.lookup(:users, userToSubscibe_id)
          followers = followers ++ [user_id]

        true ->
          [user_id]
      end

    followers
  end

  def get_following(userToSubscibe_id, user_id) do
    follow =
      cond do
        :ets.member(:following, user_id) ->
          [{_, listOfPeopleIFollow}] = :ets.lookup(:following, user_id)
          listOfPeopleIFollow ++ [userToSubscibe_id]

        true ->
          [userToSubscibe_id]
      end

    follow
  end

  def get_tweets_for_hashtag(search_hashtag) do
    tweets_for_hashtag =
      cond do
        :ets.member(:hashtags, search_hashtag) ->
          [{_, listOfTweetsforHashtag}] = :ets.lookup(:hashtags, search_hashtag)
          listOfTweetsforHashtag

        true ->
          []
      end

    tweets_for_hashtag
  end

  def get_tweets_with_mentions(search_mentions) do
    # tweets_for_mention will be list of lists
    # TODO correct this get_tweets_with_mentions as we have to search for the intersection of mention ids we send
    tweets_for_mention =
      Enum.map(search_mentions, fn search_mention ->
        cond do
          :ets.member(:mentionIds, search_mention) ->
            [{_, listOfTweetsforMention}] = :ets.lookup(:mentionIds, search_mention)
            listOfTweetsforMention

          true ->
            []
        end
      end)
    IO.puts "Tweet list is"
    IO.inspect(tweets_for_mention)
    tweets_for_mention
  end

  def delete_user(user_id) do
    :ets.delete(:users, user_id)
    :ets.delete(:userTweets, user_id)
  end

  def insert_into_userTweets(user_id, tweet) do
    :ets.insert(:userTweets, {user_id, tweet})
  end

end
