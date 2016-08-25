defmodule SecretQuestion do
  use GenStateMachine

  @vsn 1

  def start(data = {question, expected_answer} \\ {"Hello?", "world"}) when is_binary(question) and is_binary(expected_answer) do
    GenStateMachine.start_link(__MODULE__, data, name: __MODULE__)
  end

  def get_question do
    GenStateMachine.call(__MODULE__, :get_question)
  end

  def unlock do
    question = GenStateMachine.call(__MODULE__, :get_question)
    answer = (IO.gets question <> "\n") |> String.trim
    case GenStateMachine.call(__MODULE__, {:unlock, answer}) do
      {:unlocked, ref} ->
        IO.puts "Unlocked"
        new_question = (IO.gets "New secret question : ") |> String.trim
        new_answer = (IO.gets "New secret answer : ") |> String.trim
        GenStateMachine.cast(__MODULE__, {:lock, ref, {new_question, new_answer}})
        IO.puts "Locked"
      :locked ->
        IO.puts "Wrong answer. Try again."
    end
  end

  # Use this to update the state machine with new code and state
  def upgrade do
    Code.load_file __ENV__.file
    :sys.suspend __MODULE__
    :sys.change_code __MODULE__, __MODULE__, (@vsn - 1), []
    :sys.resume __MODULE__
  end


  # Callbacks

  # This gets called when the state machine starts
  # Sets an initial state and data
  def init(data) do
    {:ok, :locked, data}
  end

  # Handles get_question call. Returns the current question in the state machine
  def handle_event({:call, from}, :get_question, :locked, data = {question, _}) do
    {:keep_state_and_data, {:reply, from, question}}
  end

  # TODO: This has not been tested yet. See how postponing works
  # If somene tries to get the question while unlocked,
  # postpone the event until the state changes
  def handle_event({:call, _from}, :get_question, :unlocked, _) do
    {:keep_state_and_data, {:postpone, true}}
  end

  # Handles unlock event. If answer matches expected answer,
  # move state to unlocked after setting a unique reference.
  # The purpose of the ref is to ensure only the person who unlocked
  # can set the next question and answer, since this ref will be
  # checked when the lock event comes in.
  def handle_event({:call, from}, {:unlock, answer}, :locked, data = {question, answer}) do
    ref = make_ref
    {:next_state, :unlocked, ref, {:reply, from, {:unlocked, ref}}}
  end

  # Handles unlock event when answers do not match
  # Keeps the state and data unchanged.
  def handle_event({:call, from}, {:unlock, _answer}, :locked, _data) do
    {:keep_state_and_data, {:reply, from, :locked}}
  end

  # Handles the lock event. This will check if the event is coming from
  # the person who has periviously unlocked it by matching the ref.
  # If the refs are matching, locking happens by setting a new question and answer
  def handle_event(:cast, {:lock, ref, data = {question, answer}}, :unlocked, ref)  when is_binary(question) and is_binary(answer) do
    {:next_state, :locked, data}
  end
end
