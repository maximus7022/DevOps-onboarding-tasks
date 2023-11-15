# Launching Apache Server Docker Container with Terraform

This documentation outlines the process of using Terraform to deploy a Docker container hosting an Apache server. The solution employs Terraform configuration files to manage Docker resources, including the Docker image and container.

## Terraform Configuration Files

### `providers.tf`

The `providers.tf` file configures the required provider for Terraform and specifies the Docker provider details.

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```

- **`docker` Provider:** Configures the Docker provider with the necessary details like source and version. Additionally, it sets the Docker host to `unix:///var/run/docker.sock`.

### `main.tf`

The `main.tf` file contains the Terraform configuration for the Docker image and container resources.

```hcl
resource "docker_image" "httpd_image" {
  name = var.image
}

resource "docker_container" "httpd_container" {
  name  = var.container_name
  image = docker_image.httpd_image.image_id

  ports {
    internal = "80"
    external = "8080"
  }
}
```

- **`docker_image` Resource:** Defines the Docker image to be used for the Apache server.
- **`docker_container` Resource:** Specifies the Docker container for the Apache server using the image defined above. Additionally, it maps the internal port 80 to the external port 8080.

### `variables.tf`

The `variables.tf` file defines the input variables used in the Terraform configuration.

```hcl
variable "image" {
  default = "httpd:latest"
}

variable "container_name" {
  default = "apache-server"
}
```

- **`image` Variable:** Specifies the default Docker image to be used (in this case, `httpd:latest`).
- **`container_name` Variable:** Defines the default name for the Docker container (e.g., `apache-server`).

## Usage

To deploy the Apache server Docker container using Terraform, follow these steps:

1. **Prepare Terraform Environment:**

   Make sure you have Terraform installed and configured.

2. **Set Variables (Optional):**

   Modify the `variables.tf` file or use variable assignment to customize image and container details if needed.

3. **Initialize Terraform:**

   Run `terraform init` in the directory containing these configuration files to initialize the Terraform environment.

4. **Apply Configuration:**

   Execute `terraform apply` and approve the changes to create the Docker container with the specified Apache server.