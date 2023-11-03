{ fetchFromSourcehut, buildGo119Module, pkg-config, libxkbcommon }:
buildGo119Module rec {
  pname = "dotool";
  version = "1.3";
  src = fetchFromSourcehut {
    owner = "~geb";
    repo = pname;
    rev = version;
    hash = "sha256-z0fQ+qenHjtoriYSD2sOjEvfLVtZcMJbvnjKZFRSsMA=";
  };
  vendorSha256 = "sha256-v0uoG9mNaemzhQAiG85RequGjkSllPd4UK2SrLjfm7A=";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxkbcommon ];
  postInstall = ''
    install -D $src/80-dotool.rules $out/lib/udev/rules.d/80-dotool.rules
  '';
}
