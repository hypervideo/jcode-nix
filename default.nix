{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  openssl,
  git,
  apple-sdk_15 ? null,
}:

let
  pname = "jcode";
  version = "0.25.1";
  srcHash = "sha256-Mistes20TozmJjE4FtCLFpnXw4zC952yhXcUHkE6C0g=";
  buildCommit = "619092a5ed0dfb44c6448ee8d6d0a59254638f3f";
  buildGitDate = "2026-06-10 15:15:38 -0700";
in

rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "jcode";
    rev = "v${version}";
    hash = srcHash;
  };

  cargoHash = "sha256-1XE1NQo84D8qaQb2R0qJlfpKHdehYUHajDBnYJCwZHo=";

  cargoBuildFlags = [
    "--bin"
    "jcode"
  ];

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_15
  ];

  JCODE_RELEASE_BUILD = "1";
  JCODE_BUILD_SEMVER = version;
  JCODE_BUILD_GIT_HASH = builtins.substring 0 8 buildCommit;
  JCODE_BUILD_GIT_DATE = buildGitDate;
  JCODE_BUILD_GIT_DIRTY = "false";
  JCODE_BUILD_GIT_TAG = "v${version}";
  JCODE_BUILD_CHANGELOG_RAW = "";
  CARGO_INCREMENTAL = "0";

  # The upstream suite includes provider/OAuth and TUI integration tests that
  # require local credentials or interactive/runtime state.
  doCheck = false;

  postInstall = ''
    wrapProgram "$out/bin/jcode" \
      --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta = with lib; {
    description = "A coding agent harness with a TUI, multi-model support, and multi-session workflows";
    homepage = "https://github.com/1jehuang/jcode";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "jcode";
  };
}
