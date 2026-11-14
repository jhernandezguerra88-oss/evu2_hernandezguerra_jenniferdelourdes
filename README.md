# NexoAndes U2 — Portal Operacional en AWS (actualización inmutable)

**Estudiante:** Jennifer de Lourdes Hernández Guerra · **Asignatura:** IC106TICL

> Alcance: por indicación del docente en el chat del curso (fecha: _completar_),
> Azure no se implementa; la evaluación se realiza solo en AWS.

## Arquitectura (resumen)
VPC `10.X.0.0/16` · subredes `10.X.10.0/24` y `10.X.20.0/24` en zonas distintas ·
ALB (HTTP 80) → Target Group → ASG con Launch Template (IMDSv2, sin SSH).
Actualización: Instance Refresh rolling con capacidad base 2 y temporal 3.

## Estructura
- `environments/aws/` root module + backend S3
- `modules/aws_network`, `modules/aws_compute`
- `.github/workflows/terraform.yml` pipeline (controles → plan → gate → apply → plan posterior)
- `observacion/` scripts de la ventana de observación
- `docs/` diagrama, decisiones, referencias, declaración de IA

## Prerrequisitos
Terraform >= 1.10, AWS CLI, bucket S3 para state (fuera de Git), variables de
repositorio: `X`, `CURSO`, ``TF_STATE_BUCKET`, `AWS_REGION`;
secrets temporales: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.

## Despliegue
1. Rama `feature/...` → PR con revisión → merge a `Principal`.
2. Actions → *Run workflow* (versión, `aplicar=true`) → aprobar gate `production`.
3. Revisar plan posterior (debe salir sin cambios).

## Limpieza
`terraform destroy` desde el pipeline/entorno autorizado y consulta AWS CLI posterior
que confirme la eliminación (VPC, ALB, ASG, instancias).

## TODO antes de entregar
- [ ] X, curso y artefactos v1/v2 del docente
- [ ] Justificar IDs de `skip_check` de Checkov
- [ ] Diagrama real, referencias y declaración de IA
