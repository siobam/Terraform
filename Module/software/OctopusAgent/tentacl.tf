
resource "null_resource" "install_octopus" {
  triggers = {
    script = "${file("${path.module}/Install-Octopus.ps1")}"
    depends_on = "${var.depends_on}"
  }
  connection {
        type     = "winrm"
        host     = "${var.host}"
        user     = "${var.user}"
        password = "${var.password}"
        agent    = false
        insecure = true
        timeout  = "15m"
  }
  provisioner "file" {
    source      = "${path.module}/Install-Octopus.ps1"
    destination = "D:\\Install-Octopus.ps1"
  }
  provisioner "remote-exec" {
    inline = [
        "powershell -ExecutionPolicy Bypass -file D:\\Install-Octopus.ps1"
    ]
  }
}
resource "null_resource" "configure_octopus" {
  triggers = {
    script = "${file("${path.module}/Configure-Octopus.ps1")}"
    depends_on = "${var.depends_on}"
  }
  depends_on = ["null_resource.install_octopus"]
  connection {
        type     = "winrm"
        host     = "${var.host}"
        user     = "${var.user}"
        password = "${var.password}"
        agent    = false
        insecure = true
        timeout  = "15m"
  }
  provisioner "file" {
    source      = "${path.module}/Configure-Octopus.ps1"
    destination = "D:\\Configure-Octopus.ps1"
  }
  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      host     = "${var.host}"
      user     = "${var.user}"
      password = "${var.password}"
      agent    = false
    }
    inline = [
        "powershell -ExecutionPolicy Bypass -file D:\\Configure-Octopus.ps1 -OctopusConnectionString ${var.OctopusConnectionString}"
    ]
  }
}