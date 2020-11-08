resource "null_resource" "gen_lt" {
triggers = {
    always_run = "${timestamp()}"
}
provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        ./gen-lt.sh
        sleep5
        echo "************************************************************************************"
     EOT
}
}