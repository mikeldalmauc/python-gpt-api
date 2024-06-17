
# Express Server with JWT Authentication, ChatGPT Integration, and Statistics Tracking

- [Express Server with JWT Authentication, ChatGPT Integration, and Statistics Tracking](#express-server-with-jwt-authentication-chatgpt-integration-and-statistics-tracking)
  - [Descripción](#descripción)
  - [Estructura del Proyecto](#estructura-del-proyecto)
  - [Configuración](#configuración)
    - [Dependencias](#dependencias)
    - [Variables de Entorno](#variables-de-entorno)
    - [Iniciar el Proyecto](#iniciar-el-proyecto)
  - [Endpoints](#endpoints)
    - [Autenticación](#autenticación)
    - [Conversaciones](#conversaciones)
    - [Estadísticas](#estadísticas)
  - [Middleware](#middleware)
    - [`admin.js`](#adminjs)
  - [Modelo](#modelo)
    - [`QueryLog.js`](#querylogjs)
  - [Vistas](#vistas)
    - [`chat.ejs`](#chatejs)
    - [`home.ejs`](#homeejs)
    - [`login.ejs`](#loginejs)
  - [Contexto del Personaje](#contexto-del-personaje)
    - [`character_context.json`](#character_contextjson)
  - [Licencia](#licencia)

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

## Endpoints

### Autenticación

- `POST /auth/login`: Iniciar sesión con nombre de usuario y contraseña.
- `POST /auth/register`: Registrar un nuevo usuario. Se puede especificar el rol (`user` o `admin`).

### Conversaciones

- `POST /api/chat`: Iniciar una conversación con el personaje del videojuego. Requiere autenticación JWT.

### Estadísticas

- `GET /api/stats`: Obtener estadísticas de las consultas realizadas a ChatGPT. Solo accesible para usuarios con rol de administrador.

## Middleware

### `admin.js`

Middleware para verificar si el usuario tiene el rol de administrador. Utilizado en el endpoint `/api/stats`.

## Modelo

### `QueryLog.js`

Modelo de Mongoose para registrar consultas y respuestas a ChatGPT en MongoDB.

## Vistas

### `chat.ejs`

Página de chat para interactuar con el personaje del videojuego.

### `home.ejs`

Página de inicio.

### `login.ejs`

Página de inicio de sesión y registro.

## Contexto del Personaje

### `character_context.json`

Archivo JSON que contiene el contexto inicial del personaje, incluyendo personalidad, instrucciones y conversaciones de ejemplo.

## Licencia

Este proyecto está licenciado bajo la MIT License.

