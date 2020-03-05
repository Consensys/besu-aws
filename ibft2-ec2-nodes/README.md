# AWS Cloudformation Template to setup a private IBFT2 network using Besu

This template will create a private IBFT2 network comprising 4 Validator nodes and one extra RPC node. The Bootnode is also a Validator.

### Usage:
Please create a genesis file and keys following the [documentation](https://besu.hyperledger.org/en/stable/Tutorials/Private-Network/Create-IBFT-Network/)
Once done enter the keys and genesis file content as parameters to the template below

### Parameters:
- VpcId: The VPC ID to deploy this monitoring instance into
- VpcCidrRange: The CIDR range or IP of the VPC
- SubnetOneId, SubnetTwoId: We split the nodes across 2 subnets to demonstrate actual usage. This is the IDs of those two subnets.
- PublicCidrRange: The CIDR range or IP that is allowed to access the monitoring instance (default 0.0.0.0/0)
- BesuNodeInstanceType: The EC2 instance type to use for the nodes
- Ec2KeyPair:  The ssh key pair to use with the EC2 instance
- BesuVersion: The version of Besu to install
- BootnodeValidatorPublicKey: The public key of the bootnode. The bootnode is also validator1
- BootnodeValidatorPrivateKey: The private key of the bootnode. The bootnode is also validator1
- Validator2PrivateKey: The private key of validator2
- Validator3PrivateKey: The private key of validator3
- Validator4PrivateKey: The private key of validator4
- GenesisFile: The genesis file to use
   
    
### Production Considerations:
- We have used private IPs for the nodes becuase this allows for low latency traffic between nodes. Generally speaking you use private IPs for the nodes, the exceoption is when certain nodes need to be made available across the internet and you cannot use a VPN eg: making a bootnode accessible to someone else.
- We have used only 2 subnets to demonstrate networks within a VPC. Please use as many subnets as you require.
- Limit the IP range to only those IPs that you trust
- Please use the monitoring template in addition to this, so you can see how the network and nodes perform over time and size your instances better to match your traffic requirements.
- We have used our Ansible role to provision each node to keep things uniform - please consider doing this or using something equivalent. Please also take into account how you will perform upgrades and the like.