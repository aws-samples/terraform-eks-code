openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_keycloak.key -out certificate_keycloak.crt -subj "/CN=keycloak.local"
#openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_rabbit.key -out certificate_rabbit.crt -subj "/CN=rabbit.local"
#openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_hamster.key -out certificate_hamster.crt -subj "/CN=hamster.local"
#openssl req -new -x509 -sha256 -nodes -newkey rsa:4096 -keyout private_chipmunk.key -out certificate_chipmunk.crt -subj "/CN=chipmunk.local"
#aws acm import-certificate --certificate fileb://certificate_rabbit.crt --private-key fileb://private_rabbit.key
aws acm import-certificate --certificate fileb://certificate_keycloak.crt --private-key fileb://private_keycloak.key
#aws acm import-certificate --certificate fileb://certificate_hamster.crt --private-key fileb://private_hamster.key
#aws acm import-certificate --certificate fileb://certificate_chipmunk.crt --private-key fileb://private_chipmunk.key


