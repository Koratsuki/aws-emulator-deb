# Terraform contra el AWS Emulator

Configuracion de ejemplo para usar Terraform con el emulador local de AWS de este repositorio. El provider apunta a `https://127.0.0.1:9297` y crea un bucket S3, un objeto dentro del bucket y una cola SQS.

## Requisitos

- Terraform 1.5 o superior
- El emulador levantado (`./start.sh` desde la raiz del repositorio)
- El CA y las credenciales generados en `../.aws/emulator/9297/`

## Credenciales y certificado

El provider lee directamente los archivos que genera el emulador, asi que no necesitas exportar `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` ni `AWS_CA_BUNDLE`:

```hcl
locals {
  emulator_dir = abspath("${path.module}/../.aws/emulator/9297")
}

provider "aws" {
  shared_credentials_files = ["${local.emulator_dir}/emulator_credentials"]
  shared_config_files      = ["${local.emulator_dir}/config"]
  profile                  = "default"
  custom_ca_bundle         = "${local.emulator_dir}/ca.pem"
  # ...
}
```

Puntos importantes:

- `shared_credentials_files` apunta a `emulator_credentials`, que el emulador regenera en cada arranque. Al usar la ruta y no el contenido, el provider siempre lee las claves vigentes.
- `shared_config_files` y `profile` leen el perfil `default` del archivo `config`.
- `custom_ca_bundle` usa la ruta del host. Es obligatorio porque el `config` generado contiene `ca_bundle = /home/emulator/...`, una ruta interna del contenedor que no existe en el host. `custom_ca_bundle` tiene prioridad y corrige esa ruta.

## Uso

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

Comprobar el resultado con la CLI (ejecuta esto desde el directorio `terraform/`):

```bash
export AWS_SHARED_CREDENTIALS_FILE="$PWD/../.aws/emulator/9297/emulator_credentials"
export AWS_CONFIG_FILE="$PWD/../.aws/emulator/9297/config"
export AWS_ENDPOINT_URL="https://127.0.0.1:9297"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_CA_BUNDLE="$PWD/../.aws/emulator/9297/ca.pem"
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true

aws s3 ls
aws sqs list-queues
```

Destruir los recursos de ejemplo:

```bash
terraform destroy -auto-approve
```

## Configuracion del provider

Las opciones clave de `main.tf`:

| Opcion | Motivo |
|---|---|
| `shared_credentials_files` | Lee las claves que genera el emulador en cada arranque. |
| `shared_config_files` y `profile` | Leen el perfil `default` del `config` del emulador. |
| `custom_ca_bundle` | Confia en el certificado autofirmado usando la ruta del host. |
| `endpoints` | El provider no tiene un endpoint global; se indica el emulador por servicio. |
| `skip_credentials_validation` | Evita validar credenciales contra AWS real. |
| `skip_requesting_account_id` | Evita consultas de cuenta que el emulador puede no resolver. |
| `skip_metadata_api_check` | Evita leer el IMDS de EC2. |
| `s3_use_path_style` | S3 en emuladores requiere estilo de ruta. |

## Servicios verificados

El emulador responde a estos servicios con las operaciones basicas:

- STS
- S3
- DynamoDB
- IAM
- SQS
- Lambda
- EC2
- SSM

Anade en `endpoints` solo los servicios que uses. Algunos recursos de Terraform hacen llamadas adicionales que el emulador puede no implementar; conviene probar servicio por servicio.

## Consideraciones

- Las credenciales y el certificado cambian en cada arranque del emulador. Como el provider los lee por ruta, no hace falta cambiar la configuracion ni volver a exportar variables.
- Usa estado local (el valor por defecto). No configures un backend remoto.
- El emulador guarda los recursos en memoria. Antes de detener el contenedor ejecuta `terraform destroy` para no dejar el estado de Terraform desincronizado.
- Si reiniciaste el emulador sin destruir, no hace falta editar el estado a mano: en el siguiente `terraform plan`, Terraform refresca, detecta que los recursos ya no existen y propone recrearlos. Un `terraform apply` los restaura.
- La creacion y destruccion de una cola SQS puede tardar decenas de segundos. Es una espera del provider de Terraform, no del emulador; con AWS real ocurre lo mismo.
- El servicio del emulador esta limitado a 2 GiB de memoria (`mem_limit: 2g` y `memswap_limit: 2g` en el compose). Si supera el limite, el contenedor se detiene con codigo 137 y se pierden los recursos.
- Los recursos `aws_s3_bucket.example`, `aws_s3_object.example` y `aws_sqs_queue.example` son solo una demostracion. Adaptalos o eliminalos.
