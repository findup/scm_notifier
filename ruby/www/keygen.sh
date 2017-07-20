openssl req -x509 -nodes -days 365 -newkey rsa:1024 -subj '/C=JP/ST=Tokyo/L=Tokyo/O=Company/OU=dummy/CN=common_name' -out csr.pem -keyout pkey.pem
