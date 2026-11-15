# Terraform contra el AWS Emulator

Configuracion de ejemplo para usar Terraform con el emulador local de AWS de este repositorio. El provider apunta a `https://127.0.0.1:9297` y crea un bucket S3 de ejemplo.

## Requisitos

- Terraform 1.5 o superior
- El emulador levantado (`./start.sh` desde la raiz del repositorio)
- El CA y las credenciales generados en `../.aws/emulator/9297/`

## Credenciales y certificado

El emulador genera las credenciales y el CA en cada arranque. Exporta las variables antes de ejecutar Terraform:

```bash
# Ejecutar desde la raiz del repositorio
export AWS_ACCESS_KEY_ID=$(awk -F' = ' '/aws_access_key_id/{print $2}' .aws/emulator/9297/emulator_credentials)
export AWS_SECRET_ACCESS_KEY=$(awk -F' = ' '/aws_secret_access_key/{print $2}' .aws/emulator/9297/emulator_credentials)
export AWS_CA_BUNDLE="$PWD/.aws/emulator/9297/ca.pem"
```

`AWS_CA_BUNDLE` es necesario porque el emulador usa HTTPS con su propio certificado. No uses el archivo `config` generado tal cual: contiene rutas internas del contenedor (`/home/emulator/...`) que no existen en el host.

## Uso

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

Comprobar el resultado con la CLI:

```bash
AWS_ENDPOINT_URL=https://127.0.0.1:9297 aws s3 ls
```

Destruir los recursos de ejemplo:

```bash
terraform destroy -auto-approve
```

## Configuracion del provider

Las opciones clave de `main.tf`:

| Opcion | Motivo |
|---|---|
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

- Las credenciales cambian en cada arranque del emulador. Vuelve a exportar las variables si reinicias el contenedor.
- Usa estado local (el valor por defecto). No configures un backend remoto.
- El emulador guarda los recursos en memoria. Antes de detener el contenedor ejecuta `terraform destroy` para no dejar el estado de Terraform desincronizado. Si ya lo detuviste, tendras que limpiar el estado (`terraform state rm ...`) o empezar de cero.
- El recurso `aws_s3_bucket.example` es solo una demostracion. Adáptalo o eliminalo.
