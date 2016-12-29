# hydra-common.nix

{

  deployment.targetEnv = "virtualbox";
  deployment.virtualbox.memorySize = 2048;
  deployment.virtualbox.headless = true;

  i18n.defaultLocale = "en_US.UTF-8";

  nix.binaryCaches = [
    https://hydra.mayflower.de
    https://cache.nixos.org
  ];

  nix.binaryCachePublicKeys = [
    "hydra.mayflower.de:9knPU2SJ2xyI0KTJjtUKOGUVdR2/3cOB4VNDQThcfaY="
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];

  nix.nrBuildUsers = 30;

  services.nixosManual.showManual = false;
  services.ntp.enable = false;
  services.openssh.allowSFTP = false;
  services.openssh.passwordAuthentication = false;

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
  };

}
