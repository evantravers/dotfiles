{lib, pkgs, ...}:
{
  home.file.".config/wezterm/wezterm.lua".source = ../.config/wezterm/.wezterm.lua;

  home.activation.installWeztermProfile = lib.hm.dag.entryAfter ["writeBoundary"] ''
    tempfile=$(mktemp) \
    && ${pkgs.curl}/bin/curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo $tempfile \
    && rm $tempfile
  '';
}
