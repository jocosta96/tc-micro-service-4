#!/bin/bash

SERVICE_NAME=${1:-order}
REGION=${2:-us-east-1}

SG_ID=$(aws ssm get-parameter \
  --name "/${SERVICE_NAME}/eks/security-group-id" \
  --region "${REGION}" \
  --query 'Parameter.Value' \
  --output text 2>/dev/null || true)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  echo "SSM parameter not found, skipping IP addition"
  exit 0
fi

CURRENT_IP=$(curl -s https://checkip.amazonaws.com || true)
if [ -z "$CURRENT_IP" ]; then
  echo "Could not get current IP, skipping"
  exit 0
fi

CIDR="${CURRENT_IP}/32"

# Check if rule exists (simplified check)
if aws ec2 describe-security-group-rules \
  --region "${REGION}" \
  --filters "Name=group-id,Values=${SG_ID}" \
  --query "SecurityGroupRules[?CidrIpv4=='${CIDR}' && FromPort==\`443\`]" \
  --output text 2>/dev/null | grep -q "sgr-"; then
  echo "Rule exists for ${CIDR}"
  exit 0
fi

# Add rule
if aws ec2 authorize-security-group-ingress \
  --region "${REGION}" \
  --group-id "${SG_ID}" \
  --protocol tcp \
  --port 443 \
  --cidr "${CIDR}" 2>/dev/null; then
  echo "Added ${CIDR} to ${SG_ID}"
else
  echo "Failed to add rule, continuing"
fi

exit 0
