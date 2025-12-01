#!/bin/bash
set -e

CLUSTER_NAME="edgewave-eks"
REGION="ap-south-1"

echo "🧹 Starting full cleanup for EKS cluster: $CLUSTER_NAME in $REGION..."
echo "------------------------------------------------------------"

# Step 1: Delete EKS cluster
if eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "🚀 Deleting EKS cluster..."
  eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION" --wait
else
  echo "✅ Cluster not found. Skipping eksctl delete."
fi

# Step 2: Release Elastic IPs
echo "🔎 Checking for orphaned Elastic IPs..."
EIP_IDS=$(aws ec2 describe-addresses --region "$REGION" --query "Addresses[].AllocationId" --output text)
if [ -n "$EIP_IDS" ]; then
  for id in $EIP_IDS; do
    echo "⚠️  Releasing Elastic IP: $id"
    aws ec2 release-address --allocation-id "$id" --region "$REGION" || true
  done
else
  echo "✅ No Elastic IPs found."
fi

# Step 3: Delete orphaned load balancers
echo "🔎 Checking for orphaned ELBs..."
LB_NAMES=$(aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[].LoadBalancerName" --output text)
if [ -n "$LB_NAMES" ]; then
  for lb in $LB_NAMES; do
    echo "⚠️  Deleting load balancer: $lb"
    aws elbv2 delete-load-balancer --name "$lb" --region "$REGION" || true
  done
else
  echo "✅ No load balancers found."
fi

# Step 4: Delete dangling security groups
echo "🔎 Checking for security groups created by EKS..."
SG_IDS=$(aws ec2 describe-security-groups --region "$REGION" \
  --query "SecurityGroups[?GroupName!='default' && contains(GroupName, '$CLUSTER_NAME')].GroupId" --output text)
if [ -n "$SG_IDS" ]; then
  for sg in $SG_IDS; do
    echo "⚠️  Deleting security group: $sg"
    aws ec2 delete-security-group --group-id "$sg" --region "$REGION" || true
  done
else
  echo "✅ No EKS-related security groups found."
fi

# Step 5: Final verification
echo "🔎 Final verification..."
aws eks list-clusters --region "$REGION"
aws ec2 describe-instances --region "$REGION" --filters "Name=tag:eksctl.cluster.name,Values=$CLUSTER_NAME" --query "Reservations[*].Instances[*].InstanceId" --output text

echo "------------------------------------------------------------"
echo "✅ Cleanup complete! All EKS resources for '$CLUSTER_NAME' have been deleted."
