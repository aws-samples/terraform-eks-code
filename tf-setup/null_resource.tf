resource "null_resource" "gen_backend" {
triggers = {
    always_run = timestamp()
}
depends_on = [null_resource.sleep]
provisioner "local-exec" {
    when = create
    command = "./gen-backend.sh"
}
}


resource "null_resource" "sleep" {
triggers = {
    always_run = timestamp()
}
depends_on = [aws_dynamodb_table.terraform_locks]
provisioner "local-exec" {
    when = create
    command = "sleep 5"
}
}