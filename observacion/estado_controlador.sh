#!/usr/bin/env bash
# Registra capacidad, estado del controlador (Instance Refresh) y salud de destinos.
# Un ciclo cada 25 s (inicio a inicio) para cumplir "cada 30 s como maximo".
# Uso (CloudShell): ./estado_controlador.sh <asg-name> <target-group-arn> salida.log
set -u
ASG="${1:?asg}"; TG="${2:?tg-arn}"; OUT="${3:?salida}"
CICLO=25
trap 'echo "Registro detenido: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT"; exit 0' INT TERM
while true; do
  t0=$(date +%s)
  {
    echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    aws autoscaling describe-instance-refreshes --auto-scaling-group-name "$ASG" \
      --query 'InstanceRefreshes[0].{Estado:Status,Avance:PercentageComplete,Inicio:StartTime}' --output json
    aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
      --query 'AutoScalingGroups[0].{Deseada:DesiredCapacity,Min:MinSize,Max:MaxSize,Instancias:Instances[].{Id:InstanceId,Estado:LifecycleState,Salud:HealthStatus,LT:LaunchTemplate.Version}}' --output json
    aws elbv2 describe-target-health --target-group-arn "$TG" \
      --query 'TargetHealthDescriptions[].{Id:Target.Id,Estado:TargetHealth.State}' --output json
    echo "=== fin ciclo $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } >> "$OUT" 2>&1
  t1=$(date +%s); rest=$(( CICLO - (t1 - t0) )); [ $rest -lt 0 ] && rest=0
  sleep "$rest"
done
