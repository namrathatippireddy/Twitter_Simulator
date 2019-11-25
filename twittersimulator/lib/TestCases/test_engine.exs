defmodule TestEngine do
  use ExUnit.Case

  # Lets start with the initialization of tables and check whether the users are registered correctly

  test "register users" do
    Utils.initialize_tables()
    Utils.register_users(1)
    assert :ets.lookup(:users, 1) |> Enum.at(0) == {1, []}
  end

  # Next check whether the login and logout are working correctly
  test "login and logout users" do
    Utils.initialize_tables()
    Utils.register_users(1)
    assert :ets.lookup(:userLogIn, 1) |> Enum.at(0) == {1, true}
    Utils.logout_user(1)
    assert :ets.lookup(:userLogIn, 1) |> Enum.at(0) == {1, false}
  end

  '''
  test "scanning the tweet correctly for hashtag" do
    tweet_content = "This tweet has one hashtag #123"
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    assert Enum.member?(list_of_hashtags, "#123")
  end

  test "check if the hashtable is getting populated correctly" do
    Utils.initialize_tables()
    tweet_content = "This tweet has one hashtag #h123"
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, tweet_content)

    assert :ets.lookup(:hashtags, "#h123") |> Enum.at(0) ==
             {"#h123", ["This tweet has one hashtag #h123"]}
  end

  test "scanning the tweet correctly for mention" do
    tweet_content = "This tweet has one hashtag @123"
    list_of_mentions = Utils.get_mentions(tweet_content)
    assert Enum.member?(list_of_mentions, "@123")
  end

  test "check if the mentions table is getting populated correctly" do
    Utils.initialize_tables()
    tweet_content = "This tweet has one mention @123"
    list_of_mentions = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(list_of_mentions, tweet_content)

    assert :ets.lookup(:mentionIds, "@123") |> Enum.at(0) ==
             {"@123", ["This tweet has one mention @123"]}
  end

  test "get followers of a user" do
    Utils.initialize_tables()
    Utils.update_followers_list(2, 1)
    # According to my function, if we search users table of 2, we should get 1
    assert :ets.lookup(:users, 2) |> Enum.at(0) ==
             {2, [1]}
  end

  test "get users subscribed to" do
    Utils.initialize_tables()
    Utils.update_following_list(2, 1)
    # Now 1's following table should have 2
    assert :ets.lookup(:following, 1) |> Enum.at(0) ==
             {1, [2]}
  end

  test "check for multiple hashtags" do
    Utils.initialize_tables()
    tweet_content = "This tweet has two hashtags #h1 and #h2 "
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, tweet_content)

    assert :ets.lookup(:hashtags, "#h1") |> Enum.at(0) ==
             {"#h1", [tweet_content]}

    assert :ets.lookup(:hashtags, "#h2") |> Enum.at(0) ==
             {"#h2", [tweet_content]}
  end

  test "Check for multiple tweets and same hashtag" do
    Utils.initialize_tables()
    tweet_content1 = "This tweet has one hashtag #h1"
    tweet_content2 = "This tweet also has same hashtag #h1"
    list_of_hashtags = Utils.get_hashtags(tweet_content1)
    Utils.insert_into_hashtagTable(list_of_hashtags, tweet_content1)
    list_of_hashtags2 = Utils.get_hashtags(tweet_content2)
    Utils.insert_into_hashtagTable(list_of_hashtags2, tweet_content2)

    [{_, tweet_list_ht}] = :ets.lookup(:hashtags, "#h1")
    assert tweet_list_ht == [tweet_content1, tweet_content2]
  end
  '''
end
