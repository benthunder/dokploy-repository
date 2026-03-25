FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKSPACE_DIR=/workspace
ENV GITNEXUS_HOME=/root/.gitnexus
ENV GITNEXUS_PORT=4747

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g gitnexus@latest

WORKDIR /workspace

RUN mkdir -p /workspace /root/.gitnexus

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 4747

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["gitnexus", "serve"]
