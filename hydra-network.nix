# hydra-network.nix

{

  network.description = "Hydra Continuous Integration Server";

  hydra = import ./hydra-master.nix;
  slave1 = import ./hydra-slave.nix;
  ipfsgw = import ./ipfs-gateway.nix;

}
