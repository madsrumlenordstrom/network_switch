{
  description = "A Nix Flake providing a development environment for the Stratix IV FPGA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages = rec {
          quartus-unwrapped = pkgs.callPackage ./packages/quartus-unwrapped.nix { };
          quartus = pkgs.callPackage ./packages/quartus.nix { inherit quartus-unwrapped; };
          default = quartus;
        };

        devShells = rec {
          default = pkgs.mkShell {
            name = "stratix";
            packages = [
              pkgs.verilator
              pkgs.gtkwave
            ];
          };
          quartus = pkgs.mkShell {
            name = "stratix-quartus";
            packages = [
              self.outputs.packages.${system}.quartus
            ] ++ default.packages;
            shellHook = ''
              export LM_LICENSE_FILE=1919@quartus.ait.dtu.dk
            '';
          };
        };
      });
}
