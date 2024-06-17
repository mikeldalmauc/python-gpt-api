FROM node:14

# Establece el directorio de trabajo en /app
WORKDIR /app

#COPY ./environment/.production.env .env
COPY ./environment/dev.env .env

# Instala las dependencias del proyecto
RUN npm install
RUN npm install --save-dev nodemon


# Expone el puerto 3000 para que pueda ser accedido desde fuera del contenedor
EXPOSE 3000

# Define el comando que se ejecutará cuando el contenedor inicie
# CMD ["node", "app.js"]
CMD ["npx", "nodemon"]
