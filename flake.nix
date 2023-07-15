{
  description = "A flake for building numen";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    dotool = {
      url = sourcehut:~geb/dotool;
      flake = false;
    };
    numen = {
      url = sourcehut:~geb/numen;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, dotool, numen }: {

    packages.x86_64-linux.default =
      with import nixpkgs { system = "x86_64-linux"; };
      let vosk-bin = pkgs.stdenv.mkDerivation {
            # todo: other arches as well.
            name = "vosk-bin";
            version = "0.3.45";
            src = fetchurl {
              url = "https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-linux-x86_64-0.3.45.zip";
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
          };
          vosk-model-small-en-us = pkgs.stdenv.mkDerivation {
            name = "vosk-model-small-en-us";
            version = "0.15";
            src = fetchurl {
              url = "https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip";
              sha256 = "sha256-MPJiQsTrRJ+UjkLLMC3XpobLKaNCOoNn+Z/0F4CUJJg=";
            };
            nativeBuildInputs = [ unzip ];
            unpackCmd = "unzip $curSrc";

            installPhase = ''
              mkdir -p $out/usr/share/vosk-models
              cp -r . $out/usr/share/vosk-models/small-en-us
            '';
          };
          dotoolPkg = pkgs.buildGo119Module rec {
            pname = "dotool";
            version = "1.3";
            vendorSha256 = "sha256-v0uoG9mNaemzhQAiG85RequGjkSllPd4UK2SrLjfm7A=";
            src = dotool;
            nativeBuildInputs = [ pkg-config ];
            buildInputs = [ libxkbcommon ];
          };
      in
        pkgs.buildGo119Module rec {
          pname = "numen";
          version = "0.7";
          vendorSha256 = "sha256-Y3CbAnIK+gEcUfll9IlEGZE/s3wxdhAmTJkj9zlAtoQ=";
          src = numen;
          preBuild = ''
              export CGO_CFLAGS="-I${vosk-bin}/include"
              export CGO_LDFLAGS="-L${vosk-bin}/lib"
            '';
          nativeBuildInputs = [
            makeWrapper
            scdoc
          ];
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
              --replace /etc/numen/scripts "$out/etc/numen/scripts"
            substituteInPlace phrases/* \
              --replace /etc/numen/scripts "$out/etc/numen/scripts"
          '';
          installPhase = ''
              runHook preInstall

              install -Dm755 $GOPATH/bin/numen -t $out/bin
              export NUMEN_SKIP_BINARY=yes
              export NUMEN_SKIP_CHECKS=yes
              export NUMEN_DEFAULT_PHRASES_DIR=/etc/numen/phrases
              export NUMEN_SCRIPTS_DIR=/etc/numen/scripts
              ./install-numen.sh $out $out/bin

              runHook postInstall
            '';
          postFixup = ''
              wrapProgram $out/bin/numen \
                --prefix PATH : ${lib.makeBinPath [ dotoolPkg alsa-utils ]} \
                --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.libxkbcommon stdenv.cc.cc.lib ]} \
            '';
        };
  };
}
