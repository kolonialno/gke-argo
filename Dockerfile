FROM google/cloud-sdk:alpine

# Download and unzip Argo CLI
RUN curl -sSL -O https://github.com/argoproj/argo-workflows/releases/download/v3.0.7/argo-linux-amd64.gz
RUN gunzip argo-linux-amd64.gz

# Make executable and move to path
RUN chmod +x argo-linux-amd64
RUN mv ./argo-linux-amd64 /usr/local/bin/argo

# Add entrypoint and make executable
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
