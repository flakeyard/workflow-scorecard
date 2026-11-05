# The scripts and the tests pass shellcheck and are formatted by shfmt.
{
  perSystem =
    { pkgs, sources, ... }:
    {
      checks.shell =
        pkgs.runCommand "shell"
          {
            nativeBuildInputs = with pkgs; [
              findutils
              shellcheck
              shfmt
            ];
          }
          ''
            cd ${sources}
            scripts=$(find . -name '*.sh')
            shellcheck -x $scripts
            shfmt -d -i 2 -ci -bn $scripts
            touch $out
          '';
    };
}
