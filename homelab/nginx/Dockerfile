FROM nginx:alpine

# Install additional tools
RUN apk add --no-cache \
    bash \
    curl \
    openssl

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate for development
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx-selfsigned.key \
    -out /etc/nginx/ssl/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Create log directory
RUN mkdir -p /var/log/nginx

# Expose ports
EXPOSE 8080 8443

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD nginx -t || exit 1

CMD ["nginx", "-g", "daemon off;"]
