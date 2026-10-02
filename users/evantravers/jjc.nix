{
  lib,
  rustPlatform,
  fetchgit,
}:

rustPlatform.buildRustPackage {
  pname = "jjc";
  version = "0-unstable-2026-06-01";

  src = fetchgit {
    url = "https://tangled.org/akashina.tngl.sh/jjc";
    rev = "bb71fdcd704e8bf4ddfac9ac0e3a036cab441b2c";
    hash = "sha256-1ak6NCyjtQBipgCtHjhGZduu3tqyzS4vbdprj2UJ9/g=";
  };

  cargoHash = "sha256-ER1oW/y8IVFqJ+UxBpE1f6OiZUDbt05kbwxMD4fc6jM=";

  doCheck = false;

  meta = {
    description = "Non-interactive hunk-level operations for Jujutsu";
    homepage = "https://tangled.org/akashina.tngl.sh/jjc";
    license = lib.licenses.mit;
    mainProgram = "jjc";
  };
}
