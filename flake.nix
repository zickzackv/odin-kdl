{
  description = "A test try to read a kdl file in odin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:

  let
    systems = [ "x86_64-linux" ];
    system = builtins.elemAt systems 0;
    pkgs = import  nixpkgs { inherit system; };
  in
  {

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        odin
        ols
        cmake
        gnumake
        gcc
      ];
    };

  };
}
