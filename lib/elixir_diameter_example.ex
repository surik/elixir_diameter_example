defmodule ElixirDiameterExample do
  require Record
  use Application

  @files ["elixir_diameter_example/include/rfc4005_nas.hrl"]

  base_records = Record.extract_all(from_lib: "diameter/include/diameter.hrl") ++
                 Record.extract_all(from_lib: "diameter/include/diameter_gen_base_rfc6733.hrl")
  for {name, record} <- base_records do
    new_name = name 
               |> Atom.to_string
               |> String.replace("-", "_")
               |> String.to_atom
    Record.defrecord new_name, name, record
  end

  records = for file <- @files do
    Record.extract_all(from_lib: file)
  end
  |> List.flatten

  for {name, record} <- records do
    short_name = case Atom.to_string(name) do
      "diameter_" <> name -> String.to_atom(name)
      _ -> name
    end
    short_name = short_name
                 |> Atom.to_string
                 |> String.replace("-", "_")
                 |> String.to_atom
    Record.defrecord short_name, name, record
  end

  @app_id :rfc4005_nas.id()
  @dict :rfc4005_nas

  def start(_, _) do
    import Supervisor.Spec, warn: false
    init()
    opts = [strategy: :one_for_one, name: ElixirDiameterExample.Supervisor]
    Supervisor.start_link([], opts)
  end

  def init do
    svc_opts = [{:'Origin-Host', "example_server.com"},
                {:'Origin-Realm', "realm.example_server.com"},
                {:'Origin-State-Id', :diameter.origin_state_id()},
                {:'Vendor-Id', 0},
                {:'Product-Name', "Test diameter server"},
                {:'Auth-Application-Id', [@app_id]},
                {:string_decode, false},
                {:application, [{:alias, :diameter_server},
                                {:dictionary, @dict},
                                {:module, __MODULE__}]}]
    :ok = :diameter.start_service(__MODULE__, svc_opts)
    transport_opts =  [{:transport_module, :diameter_tcp},
                       {:transport_config, [{:reuseaddr, true},
                                           {:ip, {0,0,0,0}},
                                           {:port, 3868} ]}]
    {:ok, _} = :diameter.add_transport(__MODULE__, {:listen, transport_opts})
  end
  
  def peer_up(_service, _peer, state), do: state

  def peer_down(_service, _peer, state), do: state

  def pick_peer([peer | _], _, _service, _state), do: {:ok, peer}

  def prepare_request(packet, _service, _peer), do: {:send, packet}

  def prepare_retransmit(packet, service, peer), do: prepare_request(packet, service, peer)

  def handle_answer(diameter_packet(msg: msg), _request, _service, _peer), do: {:ok, msg}

  def handle_error(reason, _request, _service, _peer), do: {:error, reason}

  def handle_request(diameter_packet(msg: nas_RAR('Session-Id': id),
                                     errors: []) = _packet, 
                     _servive, _peer = {_, caps}) do
    diameter_caps(origin_host: {oh,_},
                  origin_realm: {orr,_}) = caps
    reply = nas_RAA('Session-Id': id,
                    'Result-Code': 2001,
                    'Origin-Host': oh,
                    'Origin-Realm': orr)
    {:reply, reply}
  end

  def handle_request(_packet, _service, _peer), do: throw({:unexpected, __MODULE__})
end
