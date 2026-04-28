# jcode-nix

Nix flake packaging for [jcode](https://github.com/1jehuang/jcode), built from the upstream Rust source release tag.

## Usage

Run directly:

```bash
nix run github:hypervideo/jcode-nix -- --help
```

Use the overlay from another flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    jcode-nix.url = "github:hypervideo/jcode-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      jcode-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ jcode-nix.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.jcode ];
        };
      }
    );
}
```

## Updating

The updater tracks the latest GitHub release, refreshes the source hash and Cargo vendor hash, and preserves release build metadata:

```bash
nix shell nixpkgs#curl nixpkgs#jq nixpkgs#git -c bash scripts/update-jcode.sh
```
