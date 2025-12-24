#!/usr/bin/env bash
set -e

echo "Waiting for NLB to become active..."

while true; do
  STATE=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "${app_nlb_arn}" \
    --query 'LoadBalancers[0].State.Code' \
    --output text)

  if [ "$STATE" = "active" ]; then
    echo "NLB is active"
    break
  fi

  echo "Current state: $STATE. Waiting..."
  sleep 10
done
