{ stdenv, fetchurl, unzip, system }:
let
  getSource = system: version: let
    sources = {
      x86_64-linux = {
        systemString = "linux-x86_64";
        sha256 = "sha256-u9yO2FxDl59kQxQoiXcOqVy/vFbP+1xdzXOvqHXF+7I=";
      };
      aarch64-linux = {
        systemString = "linux-aarch64";
        sha256 = "sha256-ReldN3Vd6wdWjnlJfX/rqMA67lqeBx3ymWGqAj/ZRUE=";
      };
      i686-linux = {
        systemString = "linux-x86";
        sha256 = "sha256-tTnvwieAlIvZji7LnBuSygizxVKhh0T3ICq3hAW44fk=";
      };
    };
  in {
    url = "https://github.com/alphacep/vosk-api/releases/download/v${version}/vosk-${(builtins.getAttr system sources).systemString}-${version}.zip";
    sha256 = (builtins.getAttr system sources).sha256;

  };
in
stdenv.mkDerivation rec {
  # todo: other arches as well.
  name = "vosk-bin";
  version = "0.3.45";
  src = fetchurl (getSource system version);
  nativeBuildInputs = [ unzip ];
  unpackCmd = "unzip $curSrc";

  installPhase = ''
    mkdir -p $out/lib
    mv libvosk.so $out/lib/
    mkdir -p $out/include
    mv vosk_api.h $out/include/
  '';
}

