self: super:

let

  build-host = super.lib.hacknix.mkNixDarwinSystem ../examples/nix-darwin/build-host.nix;
  remote-builder = super.lib.hacknix.mkNixDarwinSystem ../examples/nix-darwin/remote-builder.nix;

in
{
  examples = (super.examples or {}) // {
    nix-darwin = (super.examples.nix-darwin or {}) // {
      inherit build-host;
      inherit remote-builder;
    };
  };
}
