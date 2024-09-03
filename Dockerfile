FROM node:latest

COPY ./app /app

# Establece el directorio de trabajo en /app
WORKDIR /app

#COPY ./environment/.production.env .env
COPY ./app/.env .env

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Instala las dependencias del proyecto
RUN npm install
RUN npm install --save-dev nodemon


# Expone el puerto 3000 para que pueda ser accedido desde fuera del contenedor
EXPOSE 3000

# Define el comando que se ejecutará cuando el contenedor inicie
# CMD ["node", "app.js"]
CMD ["npx", "nodemon"]
