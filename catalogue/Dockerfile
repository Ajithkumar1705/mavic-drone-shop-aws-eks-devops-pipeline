FROM node:22.14.0-bookworm-slim

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY --chown=node:node . .
USER node

EXPOSE 8080

CMD ["node","server.js"]