{
  description = "luaminifier2 development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    my = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages."${my}";
  in {
    devShells."${my}".default = pkgs.mkShell {
      strictDeps = true;
      nativeBuildInputs = with pkgs; [
        cargo
        rustc
        rustfmt
        clippy
        bacon
      ];
      env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    };
  };
}
