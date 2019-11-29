defmodule TestEngine do
  use ExUnit.Case


  # Lets start with the initialization of tables and check whether the users are registered correctly

  test "register one user" do
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

######################################### Test hashtags ########################################

  test "parse tweet with one hashtag" do
    tweet_content = "This tweet has one hashtag #123"
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    assert Enum.member?(list_of_hashtags, "#123")
  end

  test "parse tweet with multiple hashtags" do
    tweet_content = "This tweet has one hashtag #123 #Twitter #twitter123"
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    assert list_of_hashtags == ["#123", "#Twitter", "#twitter123"]
  end

  test "check insertion with one hashtag" do
    Utils.initialize_tables()
    tweet_content = "This tweet has one hashtag #h123"
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, 1, tweet_content)

    assert :ets.lookup(:hashtags, "#h123") |> Enum.at(0) ==
             {"#h123", [{1,"This tweet has one hashtag #h123"}]}
  end

  test "check insertion of multiple hashtags" do
    Utils.initialize_tables()
    tweet_content = "This tweet has two hashtags #h1 and #h2 "
    list_of_hashtags = Utils.get_hashtags(tweet_content)
    Utils.insert_into_hashtagTable(list_of_hashtags, 1, tweet_content)

    assert :ets.lookup(:hashtags, "#h1") |> Enum.at(0) ==
             {"#h1", [{1, tweet_content}]}

    assert :ets.lookup(:hashtags, "#h2") |> Enum.at(0) ==
             {"#h2", [{1, tweet_content}]}
  end

  test "Check for multiple tweets and same hashtag" do
    Utils.initialize_tables()
    tweet_content1 = "This tweet has one hashtag #h1"
    tweet_content2 = "This tweet also has same hashtag #h1"
    list_of_hashtags = Utils.get_hashtags(tweet_content1)
    Utils.insert_into_hashtagTable(list_of_hashtags, 1, tweet_content1)
    list_of_hashtags2 = Utils.get_hashtags(tweet_content2)
    Utils.insert_into_hashtagTable(list_of_hashtags2, 1, tweet_content2)

    [{_, tweet_list_ht}] = :ets.lookup(:hashtags, "#h1")
    assert tweet_list_ht == [{1, tweet_content1}, {1, tweet_content2}]
  end

########################################################## Test Mentions #############################

  test "parse tweet for one mention" do
    tweet_content = "This tweet has one hashtag @123"
    list_of_mentions = Utils.get_mentions(tweet_content)
    assert Enum.member?(list_of_mentions, "@123")
  end

  test "parse tweet for multiple mentions" do
    tweet_content = "This tweet has one hashtag @123, @qwerty"
    list_of_mentions = Utils.get_mentions(tweet_content)
    assert list_of_mentions == ["@123", "@qwerty"]
  end

  test "check insertion in mentions Table" do
    Utils.initialize_tables()
    tweet_content = "This tweet has one mention @123"
    list_of_mentions = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(list_of_mentions, 1, tweet_content)

    assert :ets.lookup(:mentionIds, "@123") |> Enum.at(0) ==
             {"@123", [{1,"This tweet has one mention @123"}]}
  end

  test "check insertion of multiple mentions" do
    Utils.initialize_tables()
    tweet_content = "This tweet has two hashtags @user1 and @user2 "
    list_of_mentions = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(list_of_mentions, 1, tweet_content)

    assert :ets.lookup(:mentionIds, "@user1") |> Enum.at(0) ==
             {"@user1", [{1, tweet_content}]}

    assert :ets.lookup(:mentionIds, "@user2") |> Enum.at(0) ==
             {"@user2", [{1, tweet_content}]}
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


# test or calculate latency
# 1] do it for every tweet on the server in handle_tweet (time at which distribution completes - time we get the tweet)
# 2] test it once in the test cases
# 3] compute latency on the receiving client (send tweet time along with the tweet)
#######################################################Search a hashtag####################################################################

  test "Searching a hashtag" do
      Utils.initialize_tables()
      tweet_content = "This tweet has one hashtag #h123"
      list_of_hashtags = Utils.get_hashtags(tweet_content)
      Utils.insert_into_hashtagTable(list_of_hashtags, 1, tweet_content)
      assert Utils.get_tweets_for_hashtag("#h123") == [{1,tweet_content}]
  end

#################################################Searching for a mention#################################################################


test "Searching a mention" do
    Utils.initialize_tables()
    tweet_content = "This tweet has one hashtag @123"
    list_of_mentions = Utils.get_mentions(tweet_content)
    Utils.insert_into_mentionsTable(list_of_mentions, 1, tweet_content)

    assert Utils.get_tweets_with_mentions(["@123"]) == [[{1,tweet_content}]]
end

test "Searching for multiple mention" do
    Utils.initialize_tables()
    tweet_content1 = "This tweet has one hashtag @123"
    tweet_content2 = "This tweet has another hashtag @945"
    list_of_mentions1 = Utils.get_mentions(tweet_content1)
    Utils.insert_into_mentionsTable(list_of_mentions1, 1, tweet_content1)
    list_of_mentions2 = Utils.get_mentions(tweet_content2)
    Utils.insert_into_mentionsTable(list_of_mentions2, 1, tweet_content2)

    assert Utils.get_tweets_with_mentions(["@123", "@945"]) == [[{1,tweet_content1}], [{1,tweet_content2}]]
end

#################################################### Check Retweets ###############################################################

test "check retweet doesn't happen when owner tries to retweet with empty tweet list" do

  {:ok, engine} = GenServer.start_link(Engine, [], name: String.to_atom("engine"))
  {:ok, client1} =
    GenServer.start_link(Client, [["#123","#3"], 1],
      name: String.to_atom(Integer.to_string(1)))


    GenServer.cast(
      String.to_atom(to_string(1)),
        {:reTweet, 1, {1,"This is a tweet"}})


    a = :ets.lookup(:userTweets, 1)

    assert a==[]
end

test "check retweet doesn't happen when owner retweets his own tweet" do
  {:ok, engine} = GenServer.start_link(Engine, [], name: String.to_atom("engine"))
  {:ok, client1} =
    GenServer.start_link(Client, [["#123","#3"], 1],
      name: String.to_atom(Integer.to_string(1)))

      GenServer.cast(
        String.to_atom("engine"),
        {:handle_tweet, 1, 1, "This is a tweet"}
      )

    Process.sleep(20)

    GenServer.cast(
      String.to_atom(to_string(1)),
        {:reTweet, 1, {1,"This is a tweet"}})

    Process.sleep(20)

    [{_,tweet_list}] = :ets.lookup(:userTweets, 1)

    assert tweet_list==[{1, "This is a tweet"}]

  end

#
#   test "Check if the tweets are delivered to only logged in users" do
#     {:ok, engine} = GenServer.start_link(Engine, [], name: String.to_atom("engine"))
#     {:ok, client1} =
#       GenServer.start_link(Client, [["#123","#3"], 1],
#         name: String.to_atom(Integer.to_string(1)))

#       {:ok, client2} =
#           GenServer.start_link(Client, [["#123","#3"], 2],
#             name: String.to_atom(Integer.to_string(2)))
#     Utils.update_following_list(2, 1)
#     Utils.update_followers_list(2, 1)
#     # 1 is following 2 and if 2 makes a tweet, it shouldn't be received by 1 if it has logged out
#     # Now logout 1
#     Utils.logout_user(1)
#     #2 is tweeting with itself as the owner
#     GenServer.cast( String.to_atom("engine"), {:handle_tweet, 2, 2, "This is a tweet"})

#     Process.sleep(20)



#   end
#
  test "Deleting a user" do
    Utils.initialize_tables()
    Utils.register_users(1)
    Utils.insert_into_userTweets(1, [{1,"This is a tweet"}])
    Utils.delete_user(1)
    assert :ets.lookup(:userTweets, 1) == []
    assert :ets.lookup(:users, 1) == []
  end

  test "Test querying by a user; user gets all tweets subscribed to" do
    Utils.initialize_tables()
    #1 is following 2,3,4
    :ets.insert(:following, {1, [2,3,4]})
    # write some tweet for each user: 2, 3,4
    :ets.insert(:userTweets, {2, [{2,"This"}]})
    :ets.insert(:userTweets, {3, [{3,"is for"}]})
    :ets.insert(:userTweets, {4, [{4,"user 1"}]})


    list = Utils.get_subscribed_tweets(1)

    assert list == [{2,"This"},{3,"is for"},{4,"user 1"}]
  end

  test "Check for multiple tweets and same mentionid" do
    Utils.initialize_tables()
    tweet_content1 = "This tweet has one mention @hey"
    tweet_content2 = "This tweet also has same mention @hey"
    list_of_mentions = Utils.get_mentions(tweet_content1)
    Utils.insert_into_mentionsTable(list_of_mentions, 1, tweet_content1)
    list_of_mentions2 = Utils.get_mentions(tweet_content2)
    Utils.insert_into_mentionsTable(list_of_mentions2, 1, tweet_content2)

      [{_, tweets_for_mention}] = :ets.lookup(:mentionIds, "@hey")
    assert tweets_for_mention == [{1, tweet_content1}, {1, tweet_content2}]
  end

end
