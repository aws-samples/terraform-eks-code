resource "null_resource" "gen_backend" {
triggers = {
    always_run = "${timestamp()}"
}
depends_on = [null_resource.sleep]
provisioner "local-exec" {
    command = "./gen-backend.sh"
}
}


resource "null_resource" "sleep" {
triggers = {
    always_run = "${timestamp()}"
}
depends_on = [aws_dynamodb_table.terraform_locks_nodeg]
provisioner "local-exec" {
    command = "sleep 5"
}
}