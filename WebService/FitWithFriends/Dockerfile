# Use the official Node.js 21.6.2 image as the base image
FROM node:21.6.2

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the app source code to the working directory
COPY . .

# Run the preinstall script
RUN npm run build

# Expose a port for the app to listen on
EXPOSE 3000

# Start the app
CMD [ "node", "dist/app" ]
