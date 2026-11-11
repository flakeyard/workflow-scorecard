# tests/run.sh passes: the static tests of the workflows and the tests of the
# Scorecard rules, with the harness of the shell library at the commit that
# test.yaml pins, so that the pin exists once.
{
  perSystem =
    { pkgs, sources, ... }:
    let
      pin = builtins.match ".*uses: flakeyard/action-shell-lib@([0-9a-f]{40}) .*" (
        builtins.readFile ../../.github/workflows/test.yaml
      );
      shellLib =
        if pin == null then
          throw "test.yaml pins no commit of flakeyard/action-shell-lib"
        else
          builtins.fetchGit {
            url = "https://github.com/flakeyard/action-shell-lib";
            rev = builtins.head pin;
            shallow = true;
          };
    in
    {
      checks.unit =
        pkgs.runCommand "unit"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              jq
              yq-go
            ];
          }
          ''
            # The sandbox has no /usr/bin/env.
            cp -r ${sources}/. source
            cp -r ${shellLib}/. shell-lib
            chmod -R u+w source shell-lib
            patchShebangs source shell-lib
            SHELL_LIB=$PWD/shell-lib bash source/tests/run.sh
            touch $out
          '';
    };
}
