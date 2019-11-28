defmodule TwitterSimulator do
  def main() do
    simulator_pid = self()
    arguments = System.argv()

    if length(arguments) != 2 do
      IO.puts("Enter the number of users to simulate and number of tweets each user has to make")
      Process.exit(simulator_pid, reason: :normal)
    end

    number_of_users = String.to_integer(Enum.at(arguments, 0))
    number_of_tweets = String.to_integer(Enum.at(arguments, 1))

    # Start the engine
    IO.puts("Starting engine")

    {:ok, engine_name} = GenServer.start_link(Engine, [], name: String.to_atom("engine"))
    # {:ok, engine_name} = GenServer.start_link(Engine, [])
    hashtag_list =
      Enum.map(1..10, fn hashtag ->
        hashtag_id = "#h#{hashtag}"
      end)

    IO.inspect(hashtag_list)

    start_simulating(number_of_users, number_of_tweets, engine_name, hashtag_list)

    receive do
    end
  end

  def start_simulating(number_of_users, number_of_tweets, engine_name, hashtag_list) do
    # First create users i.e start clients
    # IO.puts "Number of users is #{number_of_users}"
    create_users(number_of_users, engine_name, hashtag_list)

    # Make each user do one random action

    Enum.each(1..number_of_tweets, fn _count ->
      Enum.each(1..number_of_users, fn user ->   GenServer.cast(String.to_atom(to_string(user)), {:send_tweets, number_of_users})
    end)
    end)

  end

  def create_users(num_users, engine_name, hashtag_list) do
    # IO.puts "Number of users is #{num_users}"

    Enum.each(1..num_users, fn user ->
      {:ok, _user} =
        GenServer.start_link(Client, [hashtag_list, user],
          name: String.to_atom(Integer.to_string(user))
        )

      IO.puts("registering created users")
      GenServer.cast(String.to_atom(to_string(user)), {:register})
      IO.puts("Asking users to subscribe ")
      GenServer.cast(String.to_atom(to_string(user)), {:subscribe, num_users})

    end)
  end
end
