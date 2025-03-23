FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/package*.json ./
RUN npm install --only=production

RUN ls
COPY . .
RUN mkdir -p logs
EXPOSE 3000
CMD ["node", "index.js"]
