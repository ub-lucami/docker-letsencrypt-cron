echo "Running certbot for domains $DOMAINS"

get_certificate() {
  # Gets the certificate for the domain(s) CERT_DOMAINS (a comma separated list)
  # The certificate will be named after the first domain in the list
  # To work, the following variables must be set:
  # - CERT_DOMAINS : comma separated list of domains
  # - EMAIL
  # - CONCAT
  # - args
  wget -O /etc/letsencrypt/cname-auth.py https://acme.cname.si/cname-auth.py
  chmod 700 /etc/letsencrypt/cname-auth.py
  local d=${CERT_DOMAINS//,*/} # read first domain
  echo "Getting certificate for $CERT_DOMAINS"
  certbot certonly --manual --manual-auth-hook /etc/letsencrypt/cname-auth.py --preferred-challenges dns --debug-challenges --manual-public-ip-logging-ok -d $CERT_DOMAINS
  ec=$?
  echo "certbot exit code $ec"
  if [ $ec -eq 0 ]
  then
    # if $CONCAT
    # then
      # # concat the full chain with the private key (e.g. for haproxy)
      # cat /etc/letsencrypt/live/$d/fullchain.pem /etc/letsencrypt/live/$d/privkey.pem > /certs/$d.pem
    # else
      # # keep full chain and private key in separate files (e.g. for nginx and apache)
      # cp /etc/letsencrypt/live/$d/fullchain.pem /certs/$d.pem
      # cp /etc/letsencrypt/live/$d/privkey.pem /certs/$d.key
    # fi
    # keep chain, cert and private key in separate files (required by mosquitto)
	if [[ ! -e /certs/$d ]]; then
      mkdir /certs/$d
    fi
    cp /etc/letsencrypt/live/$d/chain.pem /certs/$d/chain.pem
    cp /etc/letsencrypt/live/$d/cert.pem /certs/$d/cert.pem
    cp /etc/letsencrypt/live/$d/privkey.pem /certs/$d/privkey.pem
    echo "Certificate obtained for $CERT_DOMAINS! Your new certificates - are in /certs/$d"
  else
    echo "Cerbot failed for $CERT_DOMAINS. Check the logs for details."
  fi
}

if $SEPARATE
then
  for d in $DOMAINS
  do
    CERT_DOMAINS=$d
    get_certificate
  done
else
  CERT_DOMAINS=${DOMAINS// /,}
  get_certificate
fi
