# AWS Emulator en local con Docker

Este repositorio permite levantar el AWS Emulator en local mediante Docker y Docker Compose. El emulador escucha por HTTPS en `https://127.0.0.1:9297` y expone un endpoint de salud en `/__admin/health`.

El contenedor se construye a partir de `debian:13-slim`, instala el paquete oficial del emulador y ejecuta el proceso con el usuario `1000` (no root).

## Requisitos

- Docker Engine
- Docker Compose (plugin `docker-compose` o binario `docker-compose`)
- `sudo` disponible, solo si hace falta corregir permisos del volumen
- Puerto `9297` libre en `127.0.0.1`

## Estructura del proyecto

```
.
├── Dockerfile            # Imagen del emulador
├── docker-compose.yml    # Servicio, volumen, puerto y healthcheck
├── aws.env               # Variables de entorno del contenedor
├── start.sh              # Arranque recomendado (crea el volumen con permisos correctos)
├── .gitignore            # Excluye .aws/ y artefactos de Terraform
├── terraform/            # Configuracion de ejemplo de Terraform
└── .aws/emulator/        # Datos generados por el emulador (se crea al arrancar)
```

La carpeta `.aws/` no se versiona. Contiene credenciales y certificados generados por el emulador.

## Variables de entorno

Las variables se declaran en `aws.env` y se cargan con `env_file` en el compose.

| Variable | Valor | Descripcion |
|---|---|---|
| `HOME` | `/home/emulator` | Ruta base del usuario dentro del contenedor. Define donde se escriben los archivos del emulador. |
| `EMULATOR_TELEMETRY` | `off` | Desactiva la telemetria del emulador. |
| `DEBIAN_FRONTEND` | `noninteractive` | Definida en el Dockerfile para evitar prompts durante la instalacion. |

El puerto se controla en `docker-compose.yml` mediante el mapeo `127.0.0.1:9297:9297`. Para usar otro puerto, cambia ambos lados del mapeo y el `healthcheck`. Si cambias el puerto, debes cambiar tambien el puerto en los archivos generados, porque el emulador escribe su puerto en ellos.

## Levantar el emulador

### Opcion recomendada: script de arranque

```bash
./start.sh
```

Si el archivo no tiene permisos de ejecucion, usa `bash start.sh` o ejecuta `chmod +x start.sh` una vez.

El script hace lo siguiente:

1. Crea `./.aws/emulator` con el usuario actual.
2. Si la carpeta quedo propiedad de `root` en una ejecucion anterior, corrige la propiedad con `sudo`.
3. Ejecuta el arranque con Docker Compose (`docker-compose up -d` o `docker compose up -d`, segun la version instalada).

### Opcion manual

Si prefieres no usar el script, crea la carpeta antes de levantar. Este paso es obligatorio: si Docker crea la carpeta, lo hace como `root` y el contenedor falla por permisos.

```bash
mkdir -p ./.aws/emulator
docker-compose up -d --build
```

Al arrancar, el contenedor queda en estado `healthy` cuando el endpoint de salud responde.

## Verificar que funciona

Estado del contenedor:

```bash
docker-compose ps
```

Endpoint de salud:

```bash
curl -s --cacert .aws/emulator/9297/ca.pem https://127.0.0.1:9297/__admin/health
```

La respuesta esperada es:

```
ok
```

Ver los logs:

```bash
docker-compose logs -f aws-emulator
```

## Conectar el SDK

Al arrancar, el emulador genera estos archivos en `./.aws/emulator/9297/`:

| Archivo | Contenido |
|---|---|
| `config` | Region, endpoint y ruta del CA |
| `emulator_credentials` | `aws_access_key_id` y `aws_secret_access_key` |
| `ca.pem` | Certificado CA para TLS |
| `truststore.p12` | Truststore para clientes Java |

El archivo `config` generado referencia rutas internas del contenedor. Al usar el SDK desde el host, define las variables de entorno apuntando a las rutas del host:

```bash
export AWS_SHARED_CREDENTIALS_FILE="$PWD/.aws/emulator/9297/emulator_credentials"
export AWS_CONFIG_FILE="$PWD/.aws/emulator/9297/config"
export AWS_ENDPOINT_URL="https://127.0.0.1:9297"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_CA_BUNDLE="$PWD/.aws/emulator/9297/ca.pem"
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true

aws s3 ls
```

`AWS_CA_BUNDLE` es importante aunque uses `AWS_CONFIG_FILE`: el `config` generado contiene la ruta interna del contenedor (`/home/emulator/...`), y la variable de entorno la sobrescribe con la ruta valida del host.

Las credenciales se generan en cada arranque. No las copies a otro sitio ni las incluyas en el control de versiones; leelas siempre desde `emulator_credentials`.

## Usar Terraform contra el emulador

El directorio `terraform/` incluye una configuracion de ejemplo que apunta al emulador y crea un bucket S3, un objeto y una cola SQS. El provider lee directamente las credenciales, el perfil y el CA desde `./.aws/emulator/9297/`, asi que no necesitas exportar variables de AWS.

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Para eliminar los recursos de ejemplo:

```bash
terraform destroy -auto-approve
```

Si el emulador se reinicia, las credenciales y el certificado se regeneran, pero el provider los lee por ruta: no hace falta cambiar la configuracion ni volver a exportar nada. Consulta `terraform/README.md` para la configuracion del provider, los servicios verificados y las consideraciones sobre el estado.

## Detener y limpiar

Detener el contenedor:

```bash
docker-compose down
```

Eliminar la imagen:

```bash
docker image rm aws-emulator:latest
```

Eliminar los datos generados por el emulador:

```bash
docker-compose down
sudo rm -rf ./.aws
```

Despues de borrar `.aws`, vuelve a arrancar con `./start.sh` para que la carpeta se cree con los permisos correctos.

## Solucion de problemas

### El contenedor se reinicia en bucle con "Permission denied"

Sintoma en los logs:

```
emulator serve failed: server I/O error: Permission denied (os error 13)
```

Causa: `./.aws/emulator` pertenece a `root`, normalmente porque Docker la creo al no existir. El emulador corre como UID 1000 y no puede escribir.

Comprobacion:

```bash
ls -la .aws/
```

Si aparece `root root` en `.aws/emulator`, corrige con:

```bash
docker-compose down
sudo rm -rf ./.aws
./start.sh
```

### El contenedor aparece como "unhealthy"

Revisa los logs:

```bash
docker-compose logs --tail=50 aws-emulator
```

Verifica que el puerto `9297` no este ocupado en el host:

```bash
ss -ltnp | grep 9297
```

### Cambiar el puerto

Edita `docker-compose.yml` y ajusta el mapeo y el healthcheck. Por ejemplo, para el puerto `9300`:

```yaml
ports:
  - 127.0.0.1:9300:9300
healthcheck:
  test: ["CMD", "curl", "-s", "--cacert", "/home/emulator/.aws/emulator/9300/ca.pem", "https://127.0.0.1:9300/__admin/health"]
```

Luego recrea el contenedor:

```bash
docker-compose up -d --force-recreate
```

## Notas

- El puerto se publica solo en `127.0.0.1`, no en toda la red. No uses `-p 9297:9297` sin la IP, porque expone el emulador a otras maquinas.
- El servicio esta limitado a 2 GiB de memoria con `mem_limit: 2g` y `memswap_limit: 2g` (sin swap). Si el emulador supera el limite, el contenedor se detiene con codigo 137 y se pierden los recursos emulados.
- El emulador mantiene los recursos en memoria. Al detener el contenedor se pierden los recursos emulados, pero se conservan los archivos de credenciales y certificados en `./.aws/emulator`.
- El volumen usa un bind mount a `./.aws/emulator`. Si la carpeta no existe y Docker la crea, los permisos seran de `root` y el contenedor fallara. Usa `./start.sh` para evitarlo.

## Referencias

- Getting started with Docker: https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html
- Getting started on Linux: https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-linux.html
