FROM node:18-alpine

WORKDIR /opt/app

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm install --production

# Copy application code
COPY src/ ./src/
COPY public/ ./public/

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
