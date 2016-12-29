# hydra-master.nix

{ config, pkgs, ... }:
{
  imports = [ ./hydra-common.nix ];

  environment.etc = pkgs.lib.singleton {
    target = "nix/id_buildfarm";
    source = ./id_buildfarm;
    uid = config.ids.uids.hydra;
    gid = config.ids.gids.hydra;
    mode = "0440";
  };

  networking.firewall.allowedTCPPorts = [ config.services.hydra.port 80 4001 ];

  nix = {
    package = pkgs.nixIPFS;
    distributedBuilds = true;
    buildMachines = [
      { hostName = "slave1"; maxJobs = 1; speedFactor = 1; sshKey = "/etc/nix/id_buildfarm"; sshUser = "root"; system = "x86_64-linux"; }
    ];
    extraOptions = "auto-optimise-store = true";
  };

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.example.org";
    notificationSender = "hydra@example.org";
    port = 8080;
    extraConfig = "store-uri = file:///nix/store?secret-key=/etc/nix/hydra.example.org-1/secret";
    buildMachinesFiles = [ "/etc/nix/machines" ];
  };

  services.postgresql = {
    enable = true;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
  };

  services.ipfs = {
    enable = true;
    # The Gateway normally listens on 8080
    gatewayAddress = "/ip4/127.0.0.1/tcp/9090";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "cache.example.org" = {
        root = "/var/www/example.org/cache/";
        default = true;
      };
    };
  };

  systemd.services.hydra-manual-setup = {
    description = "Create Admin User for Hydra";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "hydra-init.service" ];
    after = [ "hydra-init.service" ];
    environment = config.systemd.services.hydra-init.environment;
    script = ''
      if [ ! -e ~hydra/.setup-is-complete ]; then
        # create admin user
        /run/current-system/sw/bin/hydra-create-user alice --full-name 'Alice Q. User' --email-address 'alice@example.org' --password foobar --role admin
        # create signing keys
        /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra.example.org-1
        /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra.example.org-1 /etc/nix/hydra.example.org-1/secret /etc/nix/hydra.example.org-1/public
        /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra.example.org-1
        /run/current-system/sw/bin/chmod 440 /etc/nix/hydra.example.org-1/secret
        /run/current-system/sw/bin/chmod 444 /etc/nix/hydra.example.org-1/public
        mkdir -p /var/www/example.org/cache
        # done
        touch ~hydra/.setup-is-complete
      fi
    '';
  };

}
