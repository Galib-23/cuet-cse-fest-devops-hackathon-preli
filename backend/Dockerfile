FROM node:20 AS builder
WORKDIR /app

# Copy package and tsconfig
COPY package*.json tsconfig.json ./

# Install dev dependencies to build TypeScript
RUN npm install

# Copy source code
COPY src ./src

# Compile TypeScript -> dist/
RUN npm run build

# Stage 2: Run compiled code
FROM node:20-alpine
WORKDIR /app

# Copy only production deps
COPY package*.json ./
RUN npm install --production

# Copy compiled JS from builder
COPY --from=builder /app/dist ./dist

EXPOSE 3847

# Run compiled app
CMD ["node", "dist/index.js"]
