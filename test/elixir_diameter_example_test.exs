defmodule ElixirDiameterExampleTest do
  use ExUnit.Case
  doctest ElixirDiameterExample

  setup_all do
    DiameterClient.init
    on_exit fn -> DiameterClient.deinit end
  end

  test "RAR - RAA" do
    sid = List.to_string(:string.join(:diameter.session_id('test'), ''))
    request = ElixirDiameterExample.nas_RAR(['Session-Id': sid,
                                             'Auth-Application-Id': 4,
                                             'Re-Auth-Request-Type': 1])
    {:ok, raa} = DiameterClient.call(request)
    assert :nas_RAA == :erlang.element(1, raa)
  end
end
