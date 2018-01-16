defmodule BsvcParser do
  use GenServer

  def start(opt \\ :line) when is_atom(opt) do
    GenServer.start_link __MODULE__, [opt], [name: :parser]
  end

  def init(opt) do
    port = Port.open {:spawn, "sim68000"}, opt

    {:ok, %{port: port}}
  end

  def command(command) do
    GenServer.cast :parser, {:command, command}
  end

  def send_to_bsvc(port, command) do
    send port, {self(), {:command, "#{command}\n"}}
  end

  def receive_from_bsvc do
    receive do
      {_port, {:data, text}} -> IO.puts text
      _ -> IO.puts "Unrecognized message from BSVC"
    end
  end

  def close() do
    GenServer.cast :parser, :close
  end

  def remove_ready(result) do
    result
    |> String.split("\n")
    |> Enum.reverse
    |> (fn [_|x] -> x end).()
    |> Enum.reverse
    |> Enum.join("\n")
  end

  ### Handlers ###
  # Casts
  def handle_cast({:command, command}, %{port: port}=state) do
    send_to_bsvc(port, command)
    {:noreply, state}
  end

  def handle_cast(:close, %{port: port}=state) do
    Port.close port
    {:stop, :normal, state}
  end

  # Infos
  def handle_info({port, {:data, {:eol, result}}}, %{port: port}=state) do
    result
    |> remove_ready
    |> IO.puts

    {:noreply, state}
  end
end
