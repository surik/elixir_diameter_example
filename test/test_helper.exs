ExUnit.start()

defmodule DiameterClient do
  @app_id :rfc4005_nas.id()
  @dict :rfc4005_nas
  
  @origin_host  "realm.example_client.com"
  @origin_realm "example_client.com"

  import ElixirDiameterExample, only: :macros

  def init do
    svc_opts = [{:'Origin-Host', @origin_host},
                {:'Origin-Realm', @origin_realm},
                {:'Origin-State-Id', :diameter.origin_state_id()},
                {:'Vendor-Id', 0},
                {:'Product-Name', "Test Diameter Client"},
                {:'Auth-Application-Id', [@app_id]},
                {:string_decode, false},
                {:application, [{:alias, :diameter_client},
                                {:dictionary, @dict},
                                {:module, __MODULE__}]}]
    :ok = :diameter.start_service(__MODULE__, svc_opts)
    transport_opts =  [{:transport_module, :diameter_tcp},
                       {:transport_config, [{:reuseaddr, true},
                                           {:raddr, {127,0,0,1}},
                                           {:rport, 3868}
                                          ]}]
    {:ok, _} = :diameter.add_transport(__MODULE__, {:connect, transport_opts})
    :timer.sleep(100)
    :ok
  end

  def deinit do
    :diameter.stop_service(__MODULE__)
    :diameter.remove_transport(__MODULE__, true)
  end
  
  def call(request), do: :diameter.call(__MODULE__, :diameter_client, request, [])

  def peer_up(_service, _peer, state), do: state

  def peer_down(_service, _peer, state), do: state

  def pick_peer([peer | _], _, _service, _state), do: {:ok, peer}

  # nas_RAR imported from ElixirDiameterExample
  def prepare_request(diameter_packet(msg: msg = nas_RAR()), _service, {_peer, caps}) do
    diameter_caps(origin_host: {oh, dh},
                  origin_realm: {orr, dr}) = caps

    msg = nas_RAR(msg, ['Origin-Host': oh,
                        'Origin-Realm': orr,
                        'Destination-Host': [dh],
                        'Destination-Realm': dr])
    {:send, msg}
  end

  def prepare_request(packet, _service, _peer), do: {:send, packet}

  def prepare_retransmit(packet, service, peer), do: prepare_request(packet, service, peer)

  def handle_answer(diameter_packet(msg: msg), _request, _service, _peer), do: {:ok, msg}

  def handle_error(reason, _request, _service, _peer), do: {:error, reason}

  def handle_request(_paccket, _service, _peer), do: throw({:unexpected, __MODULE__})
end
