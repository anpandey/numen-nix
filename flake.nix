{
  description = "A flake for building numen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    dotool-src = {
      url = "sourcehut:~geb/dotool";
      flake = false;
    };
    numen-src = {
      url = "sourcehut:~geb/numen";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, dotool-src, numen-src }:
    with import nixpkgs { system = "x86_64-linux"; };
    let
      vosk-bin = pkgs.callPackage (import ./pkgs/vosk-bin.nix) { };
      vosk-model-small-en-us =
        pkgs.callPackage (import ./pkgs/vosk-model-small-en-us.nix) { };
      dotool =
        pkgs.callPackage (import ./pkgs/dotool.nix) { inherit dotool-src; };
      numen = pkgs.callPackage (import ./pkgs/numen.nix) {
        inherit numen-src dotool vosk-bin vosk-model-small-en-us;
      };
    in
    {
      packages.x86_64-linux = {
        inherit vosk-bin vosk-model-small-en-us dotool numen;
        default = numen;
      };
      overlays.default = final: prev: {
        inherit vosk-bin vosk-model-small-en-us dotool numen;

      };
      homeManagerModules.numen-nix = (import ./modules/home-manager/numen-nix.nix) { inherit numen vosk-model-small-en-us; };
      homeManagerModule = self.homeManagerModules.numen-nix;
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
    };
}
