#!/usr/bin/env bash
# Registra estado del controlador y destinos cada 30 s (max).
# Uso: ./estado_controlador.sh <asg-name> <target-group-arn> salida.log
set -u
ASG="${1:?asg}"; TG="${2:?tg-arn}"; OUT="${3:?salida}"
while true; do
  {
    echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    aws autoscaling describe-instance-refreshes --auto-scaling-group-name "$ASG" \
      --query 'InstanceRefreshes[0].{Estado:Status,Avance:PercentageComplete}' --output json
    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
      --query 'AutoScalingGroups[0].{Deseada:DesiredCapacity,Instancias:Instances[].{Id:InstanceId,Estado:LifecycleState,Salud:HealthStatus,LT:LaunchTemplate.Version}}' --output json
    aws elbv2 describe-target-health --target-group-arn "$TG" \
      --query 'TargetHealthDescriptions[].{Id:Target.Id,Estado:TargetHealth.State}' --output json
  } >> "$OUT" 2>&1
  sleep 30
done
