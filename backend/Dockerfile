# ----------- BUILD STAGE -----------
FROM node:20-alpine AS build

ARG BUILD_COLOR=blue
ENV DEPLOY_COLOR=$BUILD_COLOR

WORKDIR /app
COPY package*.json ./
RUN npm install --only=production --no-audit --no-fund
COPY . .

# ----------- RUNTIME STAGE -----------
FROM node:20-alpine

WORKDIR /app
ARG BUILD_COLOR=blue
ENV DEPLOY_COLOR=$BUILD_COLOR
ENV NODE_ENV=production

COPY --from=build /app /app

EXPOSE 8000
CMD ["node", "src/index.js"]
