{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {

   pname = "mull-wg";
   version = "0.1.0";

   src = ./.;

   propagatedBuildInputs = [
    (pkgs.python3.withPackages (ps: with ps; [
      requests
    ]))
   ];

   installPhase = ''
    mkdir -p $out/bin
    cp $src/scripts/fetch_servers.py $out/bin/mull-wg-fetch-servers
    cp $src/scripts/start_mull_ns.sh $out/bin/mull-wg-start-ns
    cp $src/scripts/connect_wg.sh $out/bin/mull-wg-connect
    cp $src/login.sh $out/bin/mull-wg-login
   '';
}

