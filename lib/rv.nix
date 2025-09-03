{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "rv";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "spinel-coop";
    repo = "rv";
    rev = "v${version}";
    hash = "sha256:032iw4917rfnvv08np89ji0wlr4m70yip4mjf3fan19djpx1k1wn";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  doCheck = false;

  meta = with lib; {
    description = "Next-gen very fast Ruby tooling";
    homepage = "https://github.com/spinel-coop/rv";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "rv";
  };
}
