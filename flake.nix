{
  description = "Converts ansible requirements.yml into nix expression";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat = {
      url = "github:teto/flake-compat/support-packages";
      flake = false;
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, ... }:
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          self.overlay
          poetry2nix.overlays.default
        ];
      };

    in {
      packages = {
        ansible2nix = pkgs.ansible2nix;
        test = pkgs.callPackage ./tests/test.nix {};
      };

      defaultPackage = self.packages.${system}.ansible2nix;

      devShell = self.defaultPackage.${system}.overrideAttrs(oa: {
        postShellHook = ''
          export PYTHONPATH="$PWD:$PYTHONPATH"
        '';
      });
    }) // {

    overlay = final: prev: {
      ansible2nix = final.poetry2nix.mkPoetryApplication {
        projectDir = ./.;
        buildInputs = [ ];
      };

      ansibleGenerateCollection = final.callPackage ./ansible.nix {};
    };
  };
}
