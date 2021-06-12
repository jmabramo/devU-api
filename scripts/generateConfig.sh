#!/bin/bash
tmp_dir=$(mktemp -d -t config-XXXXXXXXXX)
trap 'rm -rf -- "$tmp_dir"' EXIT

templateFile=${1:-config/default.yml.template}
renderedFile=${2:-config/newconfig.yml}

cp ${templateFile} ${renderedFile}

openssl genrsa -out ${tmp_dir}/jwt_private_key.pem 3072
openssl rsa -in  ${tmp_dir}/jwt_private_key.pem -pubout -out  ${tmp_dir}/jwt_public_key.pem

openssl req -x509 -newkey rsa:4096 -keyout ${tmp_dir}/saml_signing_key.pem -subj "/CN=devu-signing.local/emailAddress=admin@devu-dev.local/C=US/ST=New York/L=Buffalo/O=DevU" -out ${tmp_dir}/saml_signing_cert.pem -nodes -days 900
openssl req -x509 -newkey rsa:4096 -keyout ${tmp_dir}/saml_encryption_key.pem -subj "/CN=devu-encryption.local/emailAddress=admin@devu-dev.local/C=US/ST=New York/L=Buffalo/O=DevU" -out ${tmp_dir}/saml_encryption_cert.pem -nodes -days 900

yq -Yi --arg jwt_private_key "$(cat ${tmp_dir}/jwt_private_key.pem)" '.auth.jwt.keys."key-1".privateKey=$jwt_private_key' -- ${renderedFile}
yq -Yi --arg jwt_public_key "$(cat ${tmp_dir}/jwt_public_key.pem)" '.auth.jwt.keys."key-1".publicKey=$jwt_public_key' -- ${renderedFile}

yq -Yi --arg saml_signing_key "$(cat ${tmp_dir}/saml_signing_key.pem)" '.auth.providers.saml.signing.privateKey=$saml_signing_key' -- ${renderedFile}
yq -Yi --arg saml_signing_cert "$(cat ${tmp_dir}/saml_signing_cert.pem)" '.auth.providers.saml.signing.certificate=$saml_signing_cert' -- ${renderedFile}

yq -Yi --arg saml_encryption_key "$(cat ${tmp_dir}/saml_encryption_key.pem)" '.auth.providers.saml.encryption.privateKey=$saml_encryption_key' -- ${renderedFile}
yq -Yi --arg saml_encryption_cert "$(cat ${tmp_dir}/saml_encryption_cert.pem)" '.auth.providers.saml.encryption.certificate=$saml_encryption_cert' -- ${renderedFile}