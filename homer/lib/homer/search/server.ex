defmodule Homer.Search.Server do

  use GenServer

  def start_link(args) do
    IO.inspect "Starting Search Server"
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {offer_request, provider} = args
    {:ok, %{provider: :"#{provider}", offer_request: offer_request}, 900_000} # shutting down after 15 min of inactivity
  end

  def handle_info(:timeout, state) do
    IO.inspect "Shutting down Search Server for inactivity"
    {:stop, :normal, state}
  end

  def handle_call({limit, :from_api}, from, state) do
    offers = apply(:"#{state.provider}", :"fetch_offers", [state.offer_request]) |> Enum.take(limit)
    {:reply, offers, state}
  end

  def handle_cast(offer_request, state) do
    new_state = state |> put_in([:offer_request], offer_request)
    {:noreply, new_state}
  end

  def handle_call({limit, :local}, from, state) do
    offers = Homer.Search.get_offers(state.offer_request, limit)
    {:reply, offers, state}
  end

  @doc """
  get offers stored in database
  """
  def list_offers(pid, limit) do
    GenServer.call(pid, {limit, :from_api}, 500000)
  end

  @doc """
  get offers from the provider specified in the state
  """
  def list_offers_local(pid, limit) do
    GenServer.call(pid, {limit, :local}, 50000)
  end

  def offer_request_updated(pid, offer_request) do
    GenServer.cast(pid, offer_request)
  end

end
