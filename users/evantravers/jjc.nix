{
  lib,
  rustPlatform,
  fetchgit,
}:

rustPlatform.buildRustPackage {
  pname = "jjc";
  version = "0-unstable-2026-05-27";

  src = fetchgit {
    url = "https://tangled.org/akashina.tngl.sh/jjc";
    rev = "492e0223d03b9e5b3fe3f33389da77b9e2e7f68f";
    hash = "sha256-HYWEN56/nnDPiAduPXNB0yc9th5RdAYvDkZeXgMhZ2g=";
  };

  cargoHash = "sha256-if73ze/idGsJ+empmj/p3WCdgi5/3R4g2dI837XgLto=";

  doCheck = false;

  meta = {
    description = "Non-interactive hunk-level operations for Jujutsu";
    homepage = "https://tangled.org/akashina.tngl.sh/jjc";
    license = lib.licenses.mit;
    mainProgram = "jjc";
  };
}
