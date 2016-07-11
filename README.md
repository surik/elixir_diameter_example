# ElixirDiameterExample

A small example of using Diameter with Elixir. It uses [mix_dia_compiler](https://github.com/xerions/mix_dia_compiler) for compile diameter dictionaries.
Please make attention how `dia/rfc4005_nas.dia` looks like. It extends `diameter_gen_base_rfc6733` and use prefix `nas`.

There is test which sends RAR and expects RAA. Run it:

    $ mix deps.get
    $ mix test
