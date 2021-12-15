defmodule Homer.Search.Duffel do

  @base_url "https://api.duffel.com/air/"
  @token "duffel_test_L8HIVLqvNcPceKMeOfxMaJFv2QdsoyEM4rdqw4BHJlx"

  def convert_duration(duration) do
    case duration |> Integer.parse do
      {ret, _} -> ret
      :error -> 0
    end
  end

  def get_time(duration) do
    [_, d, h, m, _ ] = String.split(duration, ["P", "T", "H", "M"])
    d = d |> convert_duration
    h =  h |> convert_duration
    m = m |> convert_duration
    d * 1440 + h * 60 + m
  end

  def duffel_api_call(offerRequest) do
    url = @base_url <> "offer_requests"
    body = Poison.encode!(%{
      data: %{
        slices: [
          %{
            origin: offerRequest.origin,
            destination: offerRequest.destination,
            departure_date: offerRequest.departure_date
          }
        ],
        passengers: [
          %{type: "adult"}
        ],
        cabin_class: nil
        }
      })
    headers = [{"Content-type", "application/json"}, {"Accept-Encoding", "gzip"}, {"Accept", "application/json"}, {"Content-Type", "application/json"}, {"Duffel-Version", "beta"}, {"Authorization", "Bearer " <> @token}]
    ret = HTTPoison.post!(url, body, headers, [recv_timeout: 50000])
    data = ret.body
    |> :zlib.gunzip()
    |> Poison.decode!()
    |> Map.get("data")
    |> Map.get("offers")
  end

  def fetch_offers(offerRequest) do
    duffel_api_call(offerRequest)
    |> Enum.map(fn offer_r ->
        {amount, _} = Float.parse(offer_r["total_amount"])
        first_slice = offer_r["slices"] |> Enum.at(0)
        total_duration = get_time(first_slice["duration"])
        segments_count = first_slice["segments"] |> length
        departing_at = first_slice["segments"] |> List.first |> Map.get("departing_at")
        arriving_at = first_slice["segments"] |> List.last |> Map.get("arriving_at")
        offer =  %{arriving_at: arriving_at, departing_at: departing_at, destination: offerRequest.destination, origin: offerRequest.origin, total_amount: amount, segments_count: segments_count, total_duration: total_duration}
        Homer.Search.create_offer(offer) 
        Homer.Search.Offer.changeset(%Homer.Search.Offer{}, offer) 
    end)
  end

end
