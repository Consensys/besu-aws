# AWS Cloudformation Template to Monitor Besu Nodes

This template will create an instance that will start up Prometheus & Grafana, that will automatically begin collecting metrics for any Hyperedger Besu nodes that have metrics turned on at port 9545

### Parameters:
- VpcId: The VPC ID to deploy this monitoring instance into
- SubnetId: The Subnet ID of the VPC to deploy the instance into, generally this is in a public subnet
- PublicCidrRange: The CIDR range or IP that is allowed to access the monitoring instance (default 0.0.0.0/0)
- Ec2InstanceType: The monitoring EC2 instance type
- Ec2KeyPair:  The ssh key pair to use with the EC2 instance
- BesuNodesNamePrefix: The prefix to match the Besu nodes instance names i.e prometheus will automatically collect metrics from any insntances in the vpc with names that match this regex and have metrics collection enabled on port 9545 (Default: besu-.*)
- GrafanaPassword: The password to use for the Grafana Dashboard (Default: `Password1`. User is `admin`)
    

### Production Considerations:
- In the above template we have used a simple username/password mechanism to log in to Grafana and illustrate functionality. When designing this for production use, please consider using one of the other [supported mechanisms](https://grafana.com/docs/grafana/latest/auth/generic-oauth/) such as OAUTH
- Limit the IP range to only those IPs that you trust
- Please consider using something highly available, eg: ECS with an EFS mount and an ALB in front with certs to match your domain. If you are intending on using K8S please using the K8S scraper for prometheus - see our [Kubernetes Helm charts](https://github.com/PegaSysEng/besu-kubernetes/tree/master/helm/private-network-ibft/besu) for reference templates to use
