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
            name = "vosk-model-en-us-small";
            version = "small-en-us";
            src = fetchurl {
              url = "https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip";
              sha256 = "sha256-MPJiQsTrRJ+UjkLLMC3XpobLKaNCOoNn+Z/0F4CUJJg=";
            };
            nativeBuildInputs = [ unzip ];
            unpackCmd = "unzip $curSrc";

            installPhase = ''
              mkdir -p $out/usr/local/share/vosk-models
              cp -r . $out/usr/local/share/vosk-models/small-en-us
            '';
          };
          dotoolPkg = pkgs.buildGo119Module rec {
            pname = "dotool";
            version = "1.2";
            vendorSha256 = "sha256-v0uoG9mNaemzhQAiG85RequGjkSllPd4UK2SrLjfm7A=";
            src = dotool;
          };
      in
        pkgs.buildGo119Module rec {
          pname = "numen";
          version = "0.6";
          vendorSha256 = "sha256-URfqf341AdnPA5hvcy/k1icjzRcjzLtU/84mP+3SQ7M=";
          src = numen;
          preBuild = ''
              export CGO_CFLAGS="-I${vosk-bin}/include"
              export CGO_LDFLAGS="-L${vosk-bin}/lib"
            '';
          nativeBuildInputs = [
            makeWrapper
            alsa-utils
            scdoc
          ];
          propagatedBuildInputs = [
            dotoolPkg
            mawk
          ];
          patchPhase = ''
            substituteInPlace phrases/* \
              --replace /usr/libexec/numen "$out/usr/libexec/numen"
            substituteInPlace phrasescripts/* \
              --replace /usr/libexec/numen "$out/usr/libexec/numen"
          '';
          installPhase = ''
              runHook preInstall

              mv $GOPATH/bin/numen ./speech
              export PACKAGING=TRUE
              ./install-numen.sh $out $out/bin

              substituteInPlace $out/usr/libexec/numen/numen \
                --replace /usr/libexec/numen "$out/usr/libexec/numen"
              substituteInPlace $out/usr/libexec/numen/numen \
                --replace /etc/numen "$out/etc/numen"
              substituteInPlace $out/usr/libexec/numen/scribe \
                --replace /usr/libexec/numen/awk "$out/usr/libexec/numen/awk"
              substituteInPlace $out/usr/libexec/numen/instructor \
                --replace /usr/libexec/numen/awk "$out/usr/libexec/numen/awk"

              mkdir -p $out/bin
              ln -s $out/usr/libexec/numen/numen $out/bin/numen

              runHook postInstall
            '';
          postFixup = ''
              wrapProgram $out/usr/libexec/numen/numen \
                --prefix PATH : ${lib.makeBinPath [ dotoolPkg ]} \
                --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
                --set NUMEN_MODEL ${vosk-model-small-en-us}/usr/local/share/vosk-models/small-en-us
            '';
        };
  };
}
