{ pkgs, lib, config, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "quartzar";
  home.homeDirectory = "/home/quartzar";

  # Required for the default Hyprland config
  programs.kitty.enable = true;

  xdg.enable = true;

  services.gammastep = {
    enable = true;
    provider = "manual";
    temperature = {
      day = 6500;
      night = 3400;
    };
    settings = {
      general = {
        adjustment-method = "wayland";
        fade = 1;
      };
    };
    tray = true;
    dawnTime = "6:00-7:45";
    duskTime = "19:00-22:00";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;  # Handled by the zsh-autocomplete plugin below
#     autosuggestion.enable = false;
#     syntaxHighlighting.enable = false;

    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#default";
      testbuild = "sudo nixos-rebuild test --flake /etc/nixos#default";
      sudo = "sudo ";
      python = "python3";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      skip_global_compinit=1

      # Source system-installed plugins
      source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

      # Autocomplete settings
      zstyle ':autocomplete:*' list-lines 7
      zstyle ':completion:*' menu select=long

      # Add Kagi to web-search plugin
      export ZSH_WEB_SEARCH_ENGINES=(kagi "https://kagi.com/search?q=")

      # Add command expansion display
      autoload -U add-zsh-hook

      alias_for() {
        local search=$1
        local found="$(alias $search)"
        if [[ -n $found ]]; then
          found=''${found//\\//}
          found=''${found%\'}
          found=''${found#"$search="}
          found=''${found#"'"}
          echo "''${found} $2"
        fi
      }

      expand_command_line() {
        first=$(echo "$1" | awk '{print $1;}')
        rest=$(echo "''${1//"$first"/}")
        cmd_alias="$(alias_for "''${first}" "''${rest:1}")"
        if [[ -n $cmd_alias ]]; then
          echo "\033[32m❯ \033[33m$cmd_alias\033[0m"
        fi
      }

      add-zsh-hook preexec expand_command_line
    '';

    initExtra = "source ~/.p10k.zsh";

    zplug = {
      enable = true;
      plugins = [
#         { name = "marlonrichert/zsh-autocomplete"; tags = [ "depth:1" ]; }
#         { name = "zsh-users/zsh-autosuggestions"; }
#         { name = "zsh-users/zsh-syntax-highlighting"; }
        { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; }
        { name = "plugins/web-search"; tags = [ "from:oh-my-zsh" ]; }
        { name = "plugins/copyfile"; tags = [ "from:oh-my-zsh" ]; }
        { name = "zdharma-continuum/fast-syntax-highlighting"; }
        { name = "MichaelAquilina/zsh-autoswitch-virtualenv"; }
        { name = "MichaelAquilina/zsh-you-should-use"; }
        { name = "zsh-users/zsh-history-substring-search"; }
        { name = "agkozak/zsh-z"; }
        { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
      ];
    };
  };


  home.file = {
    ".config/wlogout/layout".text = ''
    {
        "label" : "lock",
        "action" : "swaylock",
        "text" : "Lock",
        "keybind" : "l"
    }
    {
        "label" : "logout",
        "action" : "sleep 1; hyprctl dispatch exit",
        "text" : "Logout",
        "keybind" : "e"
    }
    '';

    ".config/swaylock/config".text = ''
    daemonize
    show-failed-attempts
    clock
    screenshot
    effect-blur=15x15
    effect-vignette=0.5:0.5
    color=1f1d2e80
    font="JetBrainsMonoNerdFontMono"
    indicator
    indicator-radius=200
    indicator-thickness=20
    '';
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        modules-left = ["hyprland/window"];
        modules-center = ["hyprland/workspaces"];
        modules-right = [ "cpu" "memory" "pulseaudio" "network" "custom/power" "clock" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
        };

        "hyprland/window" = {
          "separate-outputs" = true;
        };

        "custom/power" = {
          format = " ⏻ ";
          tooltip = false;
          "on-click" = "wlogout --protocol layer-shell";
        };

        cpu = {
            format = "{usage}% ";
        };

        memory = {
            "format" = "{}% ";
        };

        network = {
          #// "interface"= "wlp2*"; // (Optional) To force the use of this interface
          "format-wifi" = "{essid} ({signalStrength}%) ";
          "format-ethernet" = "{ipaddr}/{cidr} 󰈀";
          "tooltip-format" = "{ifname} via {gwaddr} 󰈁";
          "format-linked" = "{ifname} (No IP) ";
          "format-disconnected" = "Disconnected ⚠";
          "format-alt" = "{ifname}= {ipaddr}/{cidr}";
        };

        pulseaudio = {
          "scroll-step" = 5;
          format = "{volume}% {icon} {format_source}";
          "format-bluetooth" = "{volume}% {icon} {format_source}";
          "format-bluetooth-muted" = " {icon} {format_source}";
          "format-muted" = " {format_source}";
          "format-source" = "{volume}% ";
          "format-source-muted" = "";
          "format-icons" = {
            headphone = "";
            "hands-free" = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          "on-click" = "pavucontrol";
        };

        clock = {
          "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          "format-alt" = "{:%Y-%m-%d}";
        };
      };
    };
  };


  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";  # This makes Qt use GTK theme settings
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };


  # hyprland
  wayland.windowManager.hyprland = {
    enable = true;

#     plugins = [
#       inputs.hyprland-plugins.packages."${pkgs.system}".hyprtrails
#     ];

    settings = {
      monitor = [
        "desc:Dell Inc. DELL G3223Q 81S22P3, 3840x2160@143.96, 0x0, 1.5, vrr, 1"
        "desc:LG Electronics LG ULTRAGEAR 311NTLECU648, 2560x1440@164.96, auto-left, 1, vrr, 1"
      ];

      xwayland.force_zero_scaling = true;

      "$terminal" = "kitty";
      "$fileManager" = "dolphin";
      "$menu" = "rofi -show drun";
      "$mainMod" = "SUPER";

      exec-once = [
#         "eww daemon && eww open bar"
#         "swaylock"
#         "gnome-keyring-daemon --start --components=secrets"
#         "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "swww-daemon"
        "waybar"
        "gammastep -m wayland"
        "eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)"
      ];

      env = [
        "GDK_SCALE,1.5"
        "XCURSOR_SIZE,48"
        "HYPRCURSOR_SIZE,48"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 1;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 7;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 15;
          render_power = 2;
          color = "rgba(212121ee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master.new_status = "master";

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "gb";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
        };
      };

      gestures = {
        workspace_swipe = false;
      };

      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      workspace = [
        # Primary, bound to monitors
        "name:Primary, monitor:desc:Dell Inc. DELL G3223Q 81S22P3, default:true"
        "name:Secondary, monitor:desc:LG Electronics LG ULTRAGEAR 311NTLECU648, default:true"
        # Persistent secondaries
        "3, monitor:desc:Dell Inc. DELL G3223Q 81S22P3, persistent:true"
        "4, monitor:desc:LG Electronics LG ULTRAGEAR 311NTLECU648, persistent:true"
        # The rest
        "5, monitor:desc:Dell Inc. DELL G3223Q 81S22P3"
        "6, monitor:desc:LG Electronics LG ULTRAGEAR 311NTLECU648"
        "7, monitor:desc:Dell Inc. DELL G3223Q 81S22P3"
        "8, monitor:desc:LG Electronics LG ULTRAGEAR 311NTLECU648"

      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        # Moving current workspace to other monitors
        "$mainMod CTRL ALT, left, movecurrentworkspacetomonitor, l"
        "$mainMod CTRL ALT, right, movecurrentworkspacetomonitor, r"
      ];

      bindr = [
        "$mainMod, SUPER_L, exec, $menu"
      ];

      windowrule = [
        "float, polkit-kde-authentication-agent-1"
        "center, polkit-kde-authentication-agent-1"
        "size 500 300, polkit-kde-authentication-agent-1"
      ];

      windowrulev2 = [
        "suppressevent maximize, class:.*"
      ];
    };
  };
  

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.

  nixpkgs.config.allowUnfreePredicate = _: true;

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

#   home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
#  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
#   home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
#   };


  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/quartzar/etc/profile.d/hm-session-vars.sh
  #
#   home.sessionVariables = {
    # EDITOR = "emacs";
#   };

#   home.sessionVariables = {
#     SSH_AUTH_SOCK = "/run/user/${UID}/keyring/ssh";
#     GNOME_KEYRING_CONTROL = "/run/user/${UID}/keyring";
#   };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
