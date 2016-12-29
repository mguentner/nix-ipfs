{ config, pkgs, ... }:
let
  wl_path = "/var/lib/ipfs/";
  wl_name = "whitelist.conf";
in
{
  imports = [ ./hydra-common.nix ];

  networking.firewall.allowedTCPPorts = [ 80 4001 ];
  services.ipfs.enable = true;
  services.nginx = {
    enable = true;
    virtualHosts = {
      "_" = {
        default = true;
        extraConfig = ''
          location /ipfs/
          {
            try_files $uri @ipfs;
          }
        '';
        locations."@ipfs" = {
          extraConfig = ''
            proxy_pass http://127.0.0.1:8080;
          '';
        };
      };
    };
  };

  systemd.services.ipfsgw-setup = {
    description = "Init for IPFS Gateway";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "nginx.service" ];
    before = [ "nginx.service" ];
    script = ''
      mkdir -p ${wl_path}
      touch ${wl_path + wl_name}
    '';
  };

  systemd.services.nginx_reloader = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reload-or-restart nginx";
    };
  };

  systemd.paths.nginx_reloader = {
    wantedBy = [ "multi-user.target" ];
    requires = [ "ipfs.service" ];
    pathConfig = { PathChanged = "${wl_path + wl_name}"; };
  };

}
