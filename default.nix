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
  version = "0.30.2";
  srcHash = "sha256-E1fUitnQlSMnMpMhJ20yv/GtHHybDY/LBfcIX4DMkN8=";
  buildCommit = "5e7ab427edf8ccfa884cdab061e7f2fef6461368";
  buildGitDate = "2026-06-18 13:32:17 -0700";
in

rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "jcode";
    rev = "v${version}";
    hash = srcHash;
  };

  cargoHash = "sha256-1FPu5fH2s9wOJgthcDM3L26FpFyPYKbwRp4EDBgRO3M=";

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
