{ dotool-src, buildGo119Module, pkg-config, libxkbcommon }:
buildGo119Module rec {
  pname = "dotool";
  version = "1.3";
  vendorSha256 = "sha256-v0uoG9mNaemzhQAiG85RequGjkSllPd4UK2SrLjfm7A=";
  src = dotool-src;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxkbcommon ];
}
