# Use the official Node.js 21.6.2 image as the base image
FROM node:21.6.2

# Set the working directory in the container
WORKDIR /app

# Install OpenSSL
RUN apt-get update && apt-get install -y openssl

ENV FWF_AUTH_PRIVATE_KEY_PATH=./fwfAuthKey.pem
ENV FWF_AUTH_PUBLIC_KEY_PATH=./fwfAuthCert.pem

# Generate a self-signed certificate to use for tokens
RUN openssl req -x509 -newkey rsa:4096 -keyout ${FWF_AUTH_PRIVATE_KEY_PATH} -out ${FWF_AUTH_PUBLIC_KEY_PATH} -days 365 -nodes -subj "/CN=localhost"

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the app source code to the working directory
COPY . .

# Run typescript compile to make sure we have the latest changes in our /dist folder
RUN npm run build

# Expose a port for the app to listen on
EXPOSE 3000

# Start the app with debug flags
CMD [ "node", "--inspect=0.0.0.0:9229", "dist/app" ]
