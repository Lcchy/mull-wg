{
  description = "Mull-wg flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    nixosModules.mull-wg = import ./module.nix;
  };
}
