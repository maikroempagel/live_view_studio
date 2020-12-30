defmodule LiveViewStudioWeb.FlightsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Airports
  alias LiveViewStudio.Flights

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        airport: "",
        flight_number: "",
        flights: [],
        matches: [],
        loading: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Find a Flight</h1>
    <div id="search">

      <%= if @loading do %>
        <div class="loader">Loading...</div>
      <% end %>

      <div class="search">
        <form phx-submit="search-flights">
          <input type="text" name="flight_number" value="<%= @flight_number %>"
            placeholder="Flight Number"
            autofocus autocomplete="off"
            <%= if @loading, do: "readonly" %>
          />
          <button>
            <img src="images/search.svg">
          </button>
        </form>
        <form phx-submit="search-flights-by-airport" phx-change="suggest-airport">
          <input type="text" name="airport" value="<%= @airport %>"
            placeholder="Airport"
            autocomplete="off"
            list="matches"
            phx-debounce="1000"
            <%= if @loading, do: "readonly" %>
          />
          <button>
            <img src="images/search.svg">
          </button>
        </form>
      </div>

      <datalist id="matches">
        <%= for match <- @matches do %>
          <option value="<%= match %>"><%= match %></option>
        <% end %>
      </datalist>

      <div class="flights">
        <ul>
          <%= for flight <- @flights do %>
            <li>
              <div class="first-line">
                <div class="number">
                  Flight #<%= flight.number %>
                </div>
                <div class="origin-destination">
                  <img src="images/location.svg">
                  <%= flight.origin %> to
                  <%= flight.destination %>
                </div>
              </div>
              <div class="second-line">
                <div class="departs">
                  Departs: <%= format_time(flight.departure_time) %>
                </div>
                <div class="arrives">
                  Arrives: <%= format_time(flight.arrival_time) %>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("search-flights", %{"flight_number" => flight_number}, socket) do
    send(self(), {:search, flight_number})

    socket =
      assign(socket,
        flight_number: flight_number,
        loading: true
      )

    {:noreply, socket}
  end

  def handle_event("search-flights-by-airport", %{"airport" => airport}, socket) do
    send(self(), {:search_by_airport, airport})

    socket =
      assign(socket,
        airport: airport,
        loading: true
      )

    {:noreply, socket}
  end

  def handle_event("suggest-airport", %{"airport" => prefix}, socket) do
    socket = assign(socket, matches: Airports.suggest(prefix))

    {:noreply, socket}
  end

  def handle_info({:search, flight_number}, socket) do
    socket =
      case Flights.search_by_number(flight_number) do
        [] ->
          socket
          |> put_flash(:info, "No flights found for number \"#{flight_number}\"")
          |> assign(flights: [], loading: false)

        flights ->
          socket
          |> clear_flash()
          |> assign(flights: flights, loading: false)
      end

    {:noreply, socket}
  end

  def handle_info({:search_by_airport, airport}, socket) do
    socket =
      case Flights.search_by_airport(airport) do
        [] ->
          socket
          |> put_flash(:info, "No flights found for airport \"#{airport}\"")
          |> assign(flights: [], loading: false)

        flights ->
          socket
          |> clear_flash()
          |> assign(flights: flights, loading: false)
      end

    {:noreply, socket}
  end

  defp format_time(time) do
    Timex.format!(time, "%b %d at %H:%M", :strftime)
  end
end
