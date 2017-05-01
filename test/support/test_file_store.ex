defmodule Highlander.TestFileStore do
  @behaviour Highlander.FileStore

  def put(key, data, options) do
    Agent.get_and_update(__MODULE__, fn %{uploads: uploads, errors: errors, files: files} = state ->
      # check if there are any errors queued up
      {error, errors} = List.pop_at(errors, 0)

      # if there was an error, then update the state and return an error
      if error do
        state = %{
          state |
          uploads: [{:error, key, data, options} | uploads],
          errors: errors
        }

        {{:error, error}, state}
      else
        state = %{
          state |
          files: Map.put(files, key, data),
          uploads: [{:ok, key, data, options} | uploads],
          errors: errors
        }

        {:ok, state}
      end
    end)
  end

  def get(key) do
    Agent.get_and_update(__MODULE__, fn %{downloads: downloads, files: files, errors: errors} = state ->
      {error, errors} = List.pop_at(errors, 0)

      if error do
        state = %{
          state |
          downloads: [{:error, key} | downloads],
          errors: errors
        }

        {{:error, error}, state}
      else
        case Map.fetch(files, key) do
          {:ok, data} ->
            state = %{
              state |
              downloads: [{:ok, key} | downloads]
            }
            {{:ok, data}, state}
          _ ->
            state = %{
              state |
              downloads: [{:error, key} | downloads]
            }
            {{:error, :file_not_found}, state}
        end
      end
    end)
  end

  # test helpers

  def should_error(error \\ :internal_server_error) do
    Agent.update(__MODULE__, fn %{errors: errors} = state ->
      errors = [error | errors]
      %{state | errors: errors}
    end)
  end

  def put_file(key, data) do
    Agent.update(__MODULE__, fn %{files: files} = state ->
      files = Map.put(files, key, data)
      %{state | files: files}
    end)
  end

  def last_upload do
    List.first(recent_uploads())
  end

  def recent_uploads do
    Agent.get(__MODULE__, fn %{uploads: uploads} -> uploads end)
  end

  def last_download do
    List.first(recent_downloads())
  end

  def recent_downloads do
    Agent.get(__MODULE__, fn %{downloads: downloads} -> downloads end)
  end

  # agent management

  @empty_state %{uploads: [], downloads: [], errors: [], files: %{}}

  def start_link do
    Agent.start_link(fn -> @empty_state end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def clear do
    Agent.update(__MODULE__, fn _state -> @empty_state end)
  end
end
