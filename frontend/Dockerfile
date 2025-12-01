# ----------- BUILD STAGE -----------
FROM node:20-alpine AS build

# Build color (blue or green)
ARG BUILD_COLOR=blue
ENV VITE_DEPLOY_COLOR=$BUILD_COLOR

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install --no-audit --no-fund

# Copy source and build
COPY . .
RUN npm run build

# ----------- RUNTIME STAGE -----------
FROM nginx:alpine

# Copy built app to nginx html directory
COPY --from=build /app/dist /usr/share/nginx/html

# Custom NGINX config for single-page app
RUN printf 'server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  location / {\n\
    try_files $uri /index.html;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
