# tests/run.sh passes: the static tests of the workflows.
{
  perSystem =
    { pkgs, sources, ... }:
    {
      checks.unit =
        pkgs.runCommand "unit"
          {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              findutils
              jq
              yq-go
            ];
          }
          ''
            # The sandbox has no /usr/bin/env.
            cp -r ${sources}/. source
            chmod -R u+w source
            patchShebangs source
            bash source/tests/run.sh
            touch $out
          '';
    };
}
