#!/bin/bash

CLUSTER_NAME=${1:-besu}
REGION=${2:-ap-southeast-2}
SUBNETS=$3

aws ec2 create-tags --region $REGION --resources $SUBNETS \
    --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=shared

