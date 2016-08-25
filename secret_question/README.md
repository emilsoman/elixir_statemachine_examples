# SecretQuestion

## Usage

```
$ cd secret_question
$ mix deps.get
$ iex -S mix

# Start the state machine
iex> SecretQuestion.start

# Print the secret question and answer the question
# to unlock
iex> SecretQuestion.unlock

# Once unlocked, set the new secret question and answer
iex> SecretQuestion.lock
```
