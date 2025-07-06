# kubernetes_config_map_v1.sampleapp__kube-root-ca_crt:
resource "kubernetes_config_map_v1" "sampleapp__kube-root-ca_crt" {
  binary_data = {}
  data = {
    "ca.crt" = <<-EOT
-----BEGIN CERTIFICATE-----
MIIDBTCCAe2gAwIBAgIIbbEBHasYjj4wDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yNTA3MDYxNTM4MzlaFw0zNTA3MDQxNTQzMzlaMBUx
EzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDmATtROPEG/NAL3UH61/rvsMc6Vo0XUCsxOMzykABfnJljZRWj9fELlvTN
zBxchL6e5I+zejShpkT6p57j0kbM0xf9L0aIMfJdtGL6oSZNnKJcZ3FXmkhcNX8+
p7IStPG/iaAwhjow8VPgcuriN1thguo6cQ7gJptXOenPDn6H5aWgc1SYkWnpOoSh
fXyS3zup1pGOXQqMq2qUYFLPdxw3brGrBFAhHPcuvLHshLUexMKJ9hnuZHYMMpAi
hXBz1/93+tdlmV9Fz+B1ye7Opt6r1j2bSJ8iClyAWkSacW5MMQkETm9YpgL3w9Gg
WS6tFzVzSKEGxw2LyHImOCEUlMVtAgMBAAGjWTBXMA4GA1UdDwEB/wQEAwICpDAP
BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBT+XoJCaNHQ2oG83WZhZLffT5VV3TAV
BgNVHREEDjAMggprdWJlcm5ldGVzMA0GCSqGSIb3DQEBCwUAA4IBAQDBBDqyaI1G
9NSYomJGrUU91vcZx+a3FNcYs3Ncpsqb7mT9TKTmsgSp/awjORS+fczR6sBzq/h5
jCSDcORlMUCD98brgNHPiKX9B22XODdwPSsZJBg9BoGVh9luARXSdLBI7xRymLiU
WR+d4RbDZI7E0ENBj5PAL046y7RfGXVPfh1+QAIdY+T2VGy61JssieynNxgqGeZd
xxCwPTn/fxOSlOVpvgBJkbkbmM5RxhMtXLl1hT8/IHRqYy6UtzoXI92ZOSQf1QU2
IIpLVIfyYsD51KbYxbOuQsRt64vibnSsRBol+TLFUfIoZnj0xrHLiCvk/7UNuiKN
Oczd/19FWOQE
-----END CERTIFICATE-----
EOT
  }
  immutable = false

  metadata {
    annotations   = {}
    generate_name = null
    labels        = {}
    name          = "kube-root-ca.crt"
    namespace     = "sampleapp"
  }
}
