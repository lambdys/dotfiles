{ pkgs, inputs, system, lib, ... }:
let
  swayfx = {
    enable = true;
    config = ''
      blur enable
      blur_xray disable
      blur_passes 2
      blur_radius 4
      default_dim_inactive 0.3

      corner_radius 0
      shadows disable
    '';
  };
  terminal = "${pkgs.alacritty}/bin/alacritty";
  launcher = "${pkgs.rofi}/bin/rofi -show run";
  file_browser = "${pkgs.cinnamon.nemo-with-extensions}/bin/nemo";
  screenshot = let nixprs = inputs.nixprs.packages.${system};
  in {
    screen = "${nixprs.sshot}/bin/sshot --screen -o $HOME/imgs/screenshots";
    area = "${nixprs.sshot}/bin/sshot --area -o $HOME/imgs/screenshots";
  };
  widgets = {
    overlay = "${pkgs.eww}/bin/eww open overlay --toggle";
    lingering = "${pkgs.eww}/bin/eww open lingering --toggle --duration 15s";
  };

  left = "h";
  right = "l";
  up = "k";
  down = "j";
in {
  imports = [ ./waybar ];

  home.packages = with pkgs; [ swww ];

  wayland.windowManager.sway = {
    enable = true;
    package = lib.mkIf swayfx.enable inputs.swayfx.packages.${system}.default;
    # NOTE: temporary fix for swayfx crashing during build with:
    # "Cannot create GLES2 renderer: no DRM FD available"
    checkConfig = false;

    config = {
      inherit terminal;
      input."type:keyboard".xkb_layout = "br";
      defaultWorkspace = "workspace 1";
      window.titlebar = false;

      bars = [{
        command = "waybar";
        position = "bottom";
        mode = "dock";
      }];

      floating = {
        border = 1;
        titlebar = false;
      };

      gaps = {
        inner = 0;
        outer = 0;
        smartBorders = "on";
      };

      assigns = {
        "1" = [{ title = "Alacritty"; }];
        "2" = [ { title = "Firefox"; } { title = "Floorp"; } ];
        "3" = [{ title = "nemo"; }];
        "5" = [{ title = "Discord"; }];
        "6" = [{ title = "Krita"; }];
        "7" = [ { title = "Steam"; } { title = "Lutris"; } ];
        "9" = [{ title = "Obsidian"; }];
      };

      keybindings = let
        mod = "Mod4";

        controlBinds = {
          "${mod}+q" = "kill";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+q" = "exit";
        };
        layoutBinds = {
          "${mod}+t" = "layout default";
          "${mod}+r" = ''mode "resize"'';

          "${mod}+f" = "fullscreen";
          "${mod}+Space" = "floating toggle";
          "${mod}+Shift+Space" = "focus mode_toggle";
        };
        appBinds = {
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+d" = "exec ${launcher}";
          "${mod}+n" = "exec ${file_browser}";
          "Print" = "exec ${screenshot.screen}";
          "Shift+Print" = "exec ${screenshot.area}";
          "${mod}+b" = "exec ${widgets.overlay}";
          "${mod}+Shift+b" = "exec ${widgets.lingering}";
        };
        workspaceBinds = {
          switch = {
            "${mod}+1" = "workspace 1";
            "${mod}+2" = "workspace 2";
            "${mod}+3" = "workspace 3";
            "${mod}+4" = "workspace 4";
            "${mod}+5" = "workspace 5";
            "${mod}+6" = "workspace 6";
            "${mod}+7" = "workspace 7";
            "${mod}+8" = "workspace 8";
            "${mod}+9" = "workspace 9";
            "${mod}+0" = "workspace 10";
          };
          move = {
            "${mod}+Shift+1" = "move container to workspace 1";
            "${mod}+Shift+2" = "move container to workspace 2";
            "${mod}+Shift+3" = "move container to workspace 3";
            "${mod}+Shift+4" = "move container to workspace 4";
            "${mod}+Shift+5" = "move container to workspace 5";
            "${mod}+Shift+6" = "move container to workspace 6";
            "${mod}+Shift+7" = "move container to workspace 7";
            "${mod}+Shift+8" = "move container to workspace 8";
            "${mod}+Shift+9" = "move container to workspace 9";
            "${mod}+Shift+0" = "move container to workspace 10";
          };
          focus = {
            "${mod}+${up}" = "focus up";
            "${mod}+${right}" = "focus right";
            "${mod}+${down}" = "focus down";
            "${mod}+${left}" = "focus left";
          };
          shift = {
            "${mod}+Shift+${up}" = "move up";
            "${mod}+Shift+${right}" = "move right";
            "${mod}+Shift+${down}" = "move down";
            "${mod}+Shift+${left}" = "move left";
          };
        };
      in controlBinds // layoutBinds // appBinds // workspaceBinds.move
      // workspaceBinds.switch // workspaceBinds.focus // workspaceBinds.shift;

      startup = [
        { command = "${pkgs.swww}/bin/swww init"; }
        { command = terminal; }
        {
          command =
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
        }
        {
          command =
            "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
        }
      ];
    };

    # modes = {
    #   resize = {
    #     escape = "mode default";
    #     return = "mode default";
    #     ${left} = "resize shrink width 10px";
    #     "shift+${left}" = "resize shrink width 30px";
    #     ${right} = "resize grow width 10px";
    #     "shift+${right}" = "resize grow width 30px";
    #     ${down} = "resize shrink height 10px";
    #     "shift+${down}" = "resize shrink height 30px";
    #     ${up} = "resize grow height 10px";
    #     "shift+${up}" = "resize grow height 30px";
    #   };
    # };

    extraConfig = ''
      for_window [window_role="pop-up"] floating enable
      for_window [window_role="bubble"] floating enable
      for_window [window_role="task_dialog"] floating enable
      for_window [window_role="Preferences"] floating enable
      for_window [window_type="dialog"] floating enable
      for_window [window_type="menu"] floating enable
      for_window [window_role="About"] floating enable
      for_window [title="Save File"] floating enable
      ${lib.optionalString swayfx.enable swayfx.config}
    '';
  };
}
