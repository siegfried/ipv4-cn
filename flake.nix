{
  description = "A simple app to list CN IP addresses";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          R = pkgs.rWrapper.override {
            packages = with pkgs.rPackages; [
              dplyr
              readr
              curl
            ];
          };
          writeRscript = pkgs.writers.makeScriptWriter {
            interpreter = "${R}/bin/Rscript";
          };
          rLib = pkgs.stdenv.mkDerivation {
            name = "ipv4-cn-lib";
            src = ./src;
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out
              cp $src/lib.r $out
            '';
          };
        in
        {
          inherit R;
          default =
            writeRscript "/bin/ipv4-cn" # r
              ''
                source("${rLib}/lib.r")
                args <- commandArgs(trailingOnly = TRUE)
                name <- args[1]
                fetch_data() |> save_ipv4_cn(name)
              '';
        }
      );
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ self.packages.${system}.R ];
            shellHook = ''
              R
            '';
          };
        }
      );
    };
}
