resource "null_resource" "gen_idfile" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [random_id.id1]
  provisioner "local-exec" {
    when    = create
    command = <<EOT
        noout=${var.no-output}
        #idfile=$HOME/.tfid
	      #rm -f $idfile
        id=${random_id.id1.hex}
        kid=${aws_kms_key.ekskey.key_id}
        varfile="var-tfid.tf"
        sptfile="var-spots.tf"
        printf "variable \"tfid\" {\n" > $varfile
        printf "description = \"The unique ID for the project\"\n" >> $varfile
        printf "type        = string\n" >> $varfile
        printf "default     = \"%s\"\n" $id >> $varfile
        printf "}\n\n" >> $varfile
        printf "variable \"keyid\" {\n" > $varfile
        printf "description = \"The unique ID for the project\"\n" >> $varfile
        printf "type        = string\n" >> $varfile
        printf "default     = \"%s\"\n" $kid >> $varfile
        printf "}\n" >> $varfile
        il=()
        il+="["
        for i in $(ec2-instance-selector --usage-class spot -c 2 -a x86_64 -a amd64 --deny-list 't[2-3]\.*|m6\.*' -m 8Gib);do 
        il+='"'
        il+=$i
        il+='"'
        il+=','
        done
        il+="]"
        echo 'variable "spots" {' > $sptfile
        echo 'default = ' $il >> $sptfile
        echo '}' >> $sptfile
     EOT

  }
}
