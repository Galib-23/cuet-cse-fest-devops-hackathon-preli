# Simple Node.js build — no TypeScript
FROM node:20 AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY src ./src

EXPOSE 5921

CMD ["node", "src/gateway.js"]
