{ stdenv, fetchurl, unzip }:
stdenv.mkDerivation {
  name = "vosk-model-small-en-us";
  version = "0.15";
  src = fetchurl {
    url =
      "https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip";
    sha256 = "sha256-MPJiQsTrRJ+UjkLLMC3XpobLKaNCOoNn+Z/0F4CUJJg=";
  };
  nativeBuildInputs = [ unzip ];
  unpackCmd = "unzip $curSrc";

  installPhase = ''
    mkdir -p $out/usr/share/vosk-models
    cp -r . $out/usr/share/vosk-models/small-en-us
  '';
}

