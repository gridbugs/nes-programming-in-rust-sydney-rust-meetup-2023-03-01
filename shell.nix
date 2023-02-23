{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs
  ] ++ lib.optionals stdenv.isLinux [ google-chrome ];
}
