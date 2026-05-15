FROM varnish:7.5-alpine

# Install varnish modules and tools
RUN apk add --no-cache \
    varnish-modules \
    curl \
    bash

# Copy VCL configuration
COPY default.vcl /etc/varnish/default.vcl

# Expose ports
# 80: HTTP cache
# 6081: Varnish admin
EXPOSE 80 6081

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD varnishstat -1 || exit 1

# Start Varnish
CMD ["varnishd", \
     "-F", \
     "-f", "/etc/varnish/default.vcl", \
     "-a", "0.0.0.0:80", \
     "-T", "0.0.0.0:6081", \
     "-s", "malloc,${VARNISH_SIZE:-256M}"]
