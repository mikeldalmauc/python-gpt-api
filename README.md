
# Express Server with JWT Authentication, ChatGPT Integration, and Statistics Tracking

- [Express Server with JWT Authentication, ChatGPT Integration, and Statistics Tracking](#express-server-with-jwt-authentication-chatgpt-integration-and-statistics-tracking)
  - [Descripción](#descripción)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Configuración](#configuración)
    - [Dependencias](#dependencias)
    - [Variables de Entorno](#variables-de-entorno)
    - [Iniciar el Proyecto](#iniciar-el-proyecto)
  - [Conectarse a AWS](#conectarse-a-aws)
  - [Generar certificados SSL con Docker](#generar-certificados-ssl-con-docker)

## Descripción

Este proyecto es un servidor Express que utiliza JWT para autenticación, integra la API de ChatGPT y realiza un seguimiento de las estadísticas de las consultas a ChatGPT. El servidor almacena datos de usuario y conversaciones en Redis y utiliza MongoDB para registrar las consultas para fines estadísticos.

## Estructura del Proyecto

TODO 
## Configuración

### Dependencias

Asegúrate de tener Docker y Docker Compose instalados en tu máquina.

### Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con el siguiente contenido:

```plaintext
SESSION_SECRET=your_session_secret
OPENAI_API_KEY=your_openai_api_key
JWT_SECRET=your_jwt_secret
MONGO_URI=your_mongo_connection_string
```

### Iniciar el Proyecto

Para construir y ejecutar el proyecto, utiliza Docker Compose:

```sh
docker-compose --env-file ./environment/dev.env up -d --build
```

Esto construirá y ejecutará los contenedores necesarios para el servidor Express, Redis y MongoDB.

## Conectarse a AWS

```bash
ssh -i /path/key-pair-name.pem instance-user-name@instance-public-dns-name
```

```bash
ssh -i ./aws-flask-gpt-api.pem ec2-user@ec2-35-181-229-140.eu-west-3.compute.amazonaws.com
```

## Generar certificados SSL con Docker

[Generar Certificados SSL con Docker](https://github.com/stakater/dockerfile-ssl-certs-generator)

```bash
docker run -v ./certs:/certs stakater/ssl-certs-generator:1.0

docker run -v ./certs:/certs -e SSL_SUBJECT=localhost  stakater/ssl-certs-generator:1.0

docker run -v ./certs:/certs -e SSL_SUBJECT=ec2-35-181-229-140.eu-west-3.compute.amazonaws.com  stakater/ssl-certs-generator:1.0

```