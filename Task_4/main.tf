resource "docker_image" "httpd_image" {
  name = var.image
}

resource "docker_container" "httpd_container" {
  name  = var.container_name
  image = docker_image.httpd_image.image_id

  ports {
    internal = "80"
    external = "8081"
  }
}
