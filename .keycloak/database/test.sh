cd /opt/keycloak/bin/
./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password keycloakpass123
./kcadm.sh create realms -f - << EOF
{ "realm\: "demorealm", "enabled": true }
EOF
exit
