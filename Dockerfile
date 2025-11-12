# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code and configuration
COPY . .

# Build the application
RUN npx nx build sre-interview --prod

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist/apps/sre-interview ./

# Install production dependencies only
RUN npm ci --omit=dev

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Change ownership of the app directory
RUN chown -R nestjs:nodejs /app

# Switch to non-root user
USER nestjs

# Expose the application port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Start the application
CMD ["node", "main.js"]
