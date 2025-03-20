# docker/Dockerfile
FROM runatlantis/atlantis:latest

# Install Terraform
RUN apk add --no-cache curl unzip && \
    rm -f /usr/local/bin/terraform && \
    # Set the desired Terraform version
    LATEST_TERRAFORM_VERSION="1.11.2" && \
    # Download and install the specified Terraform version
    curl -fsSL https://releases.hashicorp.com/terraform/${LATEST_TERRAFORM_VERSION}/terraform_${LATEST_TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip
