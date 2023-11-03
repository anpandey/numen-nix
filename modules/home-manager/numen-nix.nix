{ numen, vosk-model-small-en-us }: { config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.numen;
in
{
  options.services.numen = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    numenPkg = mkOption {
      type = types.package;
      default = numen;
    };

    # models = mkOption {
    #   type = types.uniq types.listOf types.package;
    #   default = [vosk-model-small-en-us];
    #   example = "[vosk-model-small-en-us]";
    #   description = ''
    #     List of vosk models to be loaded by numen. They can be referred to using the index, eg. model0 or model1.
    #   '';
    # };

    model = mkOption {
      type = types.pathInStore;
      default = "${vosk-model-small-en-us}/usr/share/vosk-models/small-en-us/";
      example = "vosk-model-small-en-us";
      description = ''
        Vosk model to be loaded by numen.
      '';
    };

    phrases = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Phrases to be loaded by numen. If empty, the default phrases are used.
      '';
    };

    extraArgs = mkOption {
      type = types.singleLineStr;
      default = "";
      description = ''
        Additional arguments to be passed to numen.
      '';
    };

    dotoolXkbLayout = mkOption {
      type = types.singleLineStr;
      default = "en";
      description = ''
        The XKB keyboard layout that should be used by dotool.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.numen = {
      Unit = {
        Description = "Numen voice control";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service.Environment = [
        "DOTOOL_XKB_LAYOUT=${cfg.dotoolXkbLayout}"
        "NUMEN_MODEL=${cfg.model}"
      ];
      Service.ExecStart = "${cfg.numenPkg}/bin/numen ${cfg.extraArgs} ${lib.strings.concatStringsSep " " cfg.phrases}";
    };
  };
}
