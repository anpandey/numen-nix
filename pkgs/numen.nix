{ fetchFromSourcehut
, stdenv
, buildGo119Module
, makeWrapper
, scdoc
, dotool
, vosk-bin
, vosk-model-small-en-us
, lib
, alsa-utils
, libxkbcommon
, gnused
, gawk
, coreutils
, libnotify
, dmenu
, procps
}:
buildGo119Module rec {
  pname = "numen";
  version = "0.7";
  src = fetchFromSourcehut {
    owner = "~geb";
    repo = pname;
    rev = version;
    hash = "sha256-ia01lOP59RdoiO23b5Dv5/fX5CEI43tPHjmaKwxP+OM=";
  };
  vendorSha256 = "sha256-Y3CbAnIK+gEcUfll9IlEGZE/s3wxdhAmTJkj9zlAtoQ=";
  preBuild = ''
    export CGO_CFLAGS="-I${vosk-bin}/include"
    export CGO_LDFLAGS="-L${vosk-bin}/lib"
  '';
  nativeBuildInputs = [ makeWrapper scdoc ];
  ldflags = [
    "-X main.Version=${version}"
    "-X main.DefaultModelPackage=vosk-model-small-en-us"
    "-X main.DefaultModelPaths=${vosk-model-small-en-us}/usr/share/vosk-models/small-en-us"
    "-X main.DefaultPhrasesDir=${placeholder "out"}/etc/numen/phrases"
  ];
  # This is necessary because while the scripts are copied relative to
  # the nix store, the hard-coded paths inside the scripts themselves
  # still point outside of the store.
  patchPhase = ''
    substituteInPlace scripts/* \
      --replace /etc/numen/scripts "$out/etc/numen/scripts" \
      --replace sed ${gnused}/bin/sed \
      --replace awk ${gawk}/bin/awk \
      --replace cat ${coreutils}/bin/cat \
      --replace notify-send ${libnotify}/bin/notify-send
    substituteInPlace scripts/menu \
      --replace "-dmenu" "-${dmenu}/bin/dmenu"
    substituteInPlace scripts/displaying \
      --replace "(pgrep" "(${procps}/bin/pgrep" \
      --replace "(ps" "(${procps}/bin/ps"
    substituteInPlace phrases/* \
      --replace /etc/numen/scripts "$out/etc/numen/scripts" \
      --replace numenc "$out/bin/numenc"
    substituteInPlace numenc \
      --replace /bin/echo "${coreutils}/bin/echo" \
      --replace cat "${coreutils}/bin/cat" \
  '';
  installPhase = ''
    runHook preInstall

    install -Dm755 $GOPATH/bin/numen -t $out/bin
    export NUMEN_SKIP_BINARY=yes
    export NUMEN_SKIP_CHECKS=yes
    export NUMEN_DEFAULT_PHRASES_DIR=/etc/numen/phrases
    export NUMEN_SCRIPTS_DIR=/etc/numen/scripts
    ./install-numen.sh $out /bin

    runHook postInstall
  '';
  postFixup = ''
    wrapProgram $out/bin/numen \
      --prefix PATH : ${lib.makeBinPath [ dotool alsa-utils ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [ libxkbcommon stdenv.cc.cc.lib ]
      } \
  '';
}
