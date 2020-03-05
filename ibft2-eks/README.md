# AWS Cloudformation Template to setup a private IBFT2 network on EKS using Besu

We deploy a Cloudformation template that creates an EKS cluster (also referred to as the control plane) and a nodegroup that joins the control plane - please note these are not aws managed nodes and hence will not show up under the nodes section in the AWS EKS console. They will however show up when queried with kubectl

Once the cluster and nodes are up, we will use Helm to deploy any of the example kubernetes charts found in the [kubernetes repo](https://github.com/PegaSysEng/besu-kubernetes)

| ⚠️ **Note**: After you have familiarised yourself with the examples in this repo, it is recommended that you design your network based on your needs, taking these [guidelines](https://github.com/PegaSysEng/besu-kubernetes/blob/master/README.md) into account |
| --- |

### Prerequisites:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/)
- [AWS CLI 1.17 or greater ](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- Existing VPC with a minimum of 3 private and 3 public subnets - if you have lesser than this please edit the template `cfn-besu-ibft2-eks.yml` accordingly to suit
- [JQ](https://stedolan.github.io/jq/)

### Usage:
1. Deploy the cloudformation template `cfn-besu-ibft2-eks.yml` and use parameters based on your vpc. This can be done via the console or via cli (command below). Alternatively you can spin up a cluster with nodes via the Console and proceed from step 2.

```bash
aws cloudformation deploy --template `pwd`/cfn-besu-ibft2-eks.yml --stack-name besu-eks-stack --parameter-overrides VpcId=vpc-abc \ 
        PublicSubnetAId=subnet- PublicSubnetBId=subnet- PublicSubnetCId=subnet- PrivateSubnetAId=subnet- PrivateSubnetBId=subnet- PrivateSubnetCId=subnet- \ 
        NodeKeyPair=your-ec2-keypair    
```

2. Authenticate from your machine to the cluster

Refer: https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html

Create a new kube config file for your cluster
```
mkdir .kube
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME> --kubeconfig .kube/config
```

Verify you have connectivity to the cluster
```
kubectl get svc
```
should return something similar to this:

    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   21m


3. Allow the nodes to join the Cluster

Refer: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

Run the script to insert the newly created NodeInstanceRole's ARN (found in the CloudFormation template outputs) into the `aws-auth-cm.yml` file. The template is located in the 'templates' directory.
`create_aws_auth_cm.sh <CFN_STACK_NAME> <AWS_REGION>`
where: CFN_STACK_NAME is the name given when deploying the cloudformation stack in step 1


Alternatively, if you haven't used Cloudformation to deploy the cluster etc:
- copy the aws-auth-cm.yml from the templates folder to the main level.
- please find the appropriate NODE_INSTANCE_ROLE_ARN for your cluster and insert that in place of `NODE_INSTANCE_ROLE_ARN` in that file

Apply the configmap
```
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl apply -f aws-auth-cm.yaml
```

Verify the nodes show up as 'Ready'
```
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl get nodes
```
should return something similar to this:

    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   21m



At this point the cluster and nodes are ready to have deployments made to them

4. The first deployment we will apply is to install metrics and then the k8s dashboard

Refer: https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

The Kubernetes metrics server is an aggregator of resource usage data in your cluster, and it is not deployed by default in Amazon EKS clusters. The Kubernetes dashboard uses the metrics server to gather metrics for your cluster, such as CPU and memory usage over time.

Install metrics

```bash
DOWNLOAD_URL=$(curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url)
DOWNLOAD_VERSION=$(grep -o '[^/v]*$' <<< $DOWNLOAD_URL)
curl -Ls $DOWNLOAD_URL -o metrics-server-$DOWNLOAD_VERSION.tar.gz
mkdir metrics-server-$DOWNLOAD_VERSION
tar -xzf metrics-server-$DOWNLOAD_VERSION.tar.gz --directory metrics-server-$DOWNLOAD_VERSION --strip-components 1
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl apply -f metrics-server-$DOWNLOAD_VERSION/deploy/1.8+/
```

Deploy the dashboard

```bash
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

Update permissions: By default, the Kubernetes dashboard user has limited permissions. Create an eks-admin service account and cluster role binding that you can use to securely connect to the dashboard with admin-level permissions
```
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl apply -f eks-admin-sa.yml
```

Retrieve an authentication token for the eks-admin service account. Copy the <authentication_token> value from the output. Watch for new lines in the token when pasting from terminal, hence we pipe to file
```
# get the exact name of the secret
EKS_ADMIN_SECRET_NAME=`KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl -n kube-system get secrets | grep 'eks-admin' | awk '{print $1}'`
# get the value of the secret -
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl -n kube-system describe secret $EKS_ADMIN_SECRET_NAME > /tmp/token.txt
```
Copy the token value from /tmp/token.txt`

Now start the proxy
```
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl proxy &
```

Open the dashboard endpoint in a web browser: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login.
and choose **Token**, paste the <authentication_token> output from the `/tmp/token.txt`  into the **Token** field, and choose **SIGN IN**

Now you should be able to get a lot of visibility into the cluster via the dashboard GUI

5. Deploy the Besu chart

Clone the example [besu kubernetes repo](https://github.com/PegaSysEng/besu-kubernetes) and select one of the helm deployments.

Lets say 'ibft2' so to deploy the chart:

```
cd helm\ibft2
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config helm install besu ./besu
```

This will deploy the block chain network in the 'besu' namespace and the prometheus and grafana monitoring in the 'monitoring' namespace

6. To view the grafana dashboard we need to install an ingress controller and rules to route:

```bash

KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config helm repo add stable https://kubernetes-charts.storage.googleapis.com/
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config helm install grafana-ingress stable/nginx-ingress --namespace monitoring --set controller.replicaCount=2 --set rbac.create=true
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config kubectl apply -f ingress-rules-grafana.yml
```

7. To search for other charts or repos for charts to deploy:

```bash
KUBECONFIG=$KUBECONFIG:/path/to/repo/ibft2-k8s/.kube/config helm search hub nginx-ingress
```

8. To add mode users and permission your cluster by IAMs
Refer: https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
