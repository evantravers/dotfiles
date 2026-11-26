# wt — worktree + agent launcher for rex; see wt/main.go. The rex
# home-manager module (users/evantravers/rex.nix) wraps it with the PATH
# its panes need.
{ buildGoModule }:

buildGoModule {
  pname = "wt";
  version = "0.1.0";
  src = ./wt;
  vendorHash = null;
  meta.mainProgram = "wt";
}
