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
  version = "0.44.0";
  srcHash = "sha256-JZg7QoDOoM5tNFQhxBtPmB96aCnecxeI8bRbIQ2f5vc=";
  buildCommit = "ee9476aec7051498ea01ecdfd4b1df4644dbecf5";
  buildGitDate = "2026-07-11 18:26:29 -0700";
in

rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "jcode";
    rev = "v${version}";
    hash = srcHash;
  };

  cargoHash = "sha256-vByZRDCu7/icyRYmOFJqzGQe3xXVgB0XJeRJrn3qKOk=";

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
