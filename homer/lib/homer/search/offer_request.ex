defmodule Homer.Search.OfferRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @airlines ["AF", "AI", "BA", "FR"]

  schema "offer_requests" do
    field :allowed_airlines, {:array, :string}
    field :departure_date, :date
    field :destination, :string
    field :origin, :string
    field :sort_by, Ecto.Enum, values: [:total_amount, :total_duration]
    timestamps()
  end

  @doc false
  def changeset(offer_request, attrs) do
    offer_request
    |> cast(attrs, [:origin, :destination, :departure_date, :sort_by])
    |> validate_required([:origin, :destination, :departure_date])
    |> validate_format(:destination, ~r/(.*[a-z]){3}/i, [message: "Please provide a valid IATA code for destination"])
    |> validate_format(:origin, ~r/(.*[a-z]){3}/i, [message: "Please provide a valid IATA code for origin"])
    |> add_sort_by_if_missing()
    |> put_change(:allowed_airlines, @airlines)
  end

  defp add_sort_by_if_missing(%Ecto.Changeset{changes: %{sort_by: _}} = changeset) do
    changeset
  end

  defp add_sort_by_if_missing(%Ecto.Changeset{data: %Homer.Search.OfferRequest{sort_by: nil}} = changeset) do
    changeset
    |> put_change(:sort_by, :total_amount)
  end

  defp add_sort_by_if_missing(changeset) do
    changeset
  end
end
