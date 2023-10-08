{ stdenv, fetchurl, unzip }:
stdenv.mkDerivation {
  # todo: other arches as well.
  name = "vosk-bin";
  version = "0.3.45";
  src = fetchurl {
    url =
      "https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-linux-x86_64-0.3.45.zip";
    sha256 = "sha256-u9yO2FxDl59kQxQoiXcOqVy/vFbP+1xdzXOvqHXF+7I=";
  };
  nativeBuildInputs = [ unzip ];
  unpackCmd = "unzip $curSrc";

  installPhase = ''
    mkdir -p $out/lib
    mv libvosk.so $out/lib/
    mkdir -p $out/include
    mv vosk_api.h $out/include/
  '';
}

