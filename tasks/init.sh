#!/bin/bash

#-------------------------------------------------------
# file:         init.sh
# comment:      Install and manage the certificate signed by the sites
# https://www.sslforfree.com
# https://zerossl.com
# https://gethttpsforfree.com
# Also creates the certificate in JKS format.
# author:       Aecio Pires <aeciopires@gmail.com>
# date:         24-abr-2018
# revision:     Aecio Pires <aeciopires@gmail.com>
# last updated: 30-abr-2018, 09:47
#-------------------------------------------------------

#By default tasks take arguments as environment variables, prefixed with PT
# (short for Puppet Tasks)
# https://github.com/puppetlabs/tasks-hands-on-lab/tree/master/5-writing-tasks

#----------------------------------------------------
function isroot(){
	MYUID=$(id | cut -d= -f2 | cut -d\( -f1)
	[ "$MYUID" -eq 0 ] && echo YES && return 0 || echo NO && return 1
}

#------------------------------------------------------------
function install_essential_packages(){
PACKAGES="$1"
echo "[INFO] Installing necessary packages..."
case "$LINUXDISTRO" in
  DEBIAN|UBUNTU)
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install -y $PACKAGES > /dev/null 2>&1
  ;;
  CENTOS|REDHAT)
    yum -y install $PACKAGES > /dev/null 2>&1
  ;;
  *)
    echo "[ERROR] I don't know how to install packages [$PACKAGES] in this \
          distro: $LINUXDISTRO." && exit 3
    ;;
  esac
}

#------------------------------------------------------------
function check_essential_commands(){

PACKAGES="$1"

echo "[INFO] Checking in the system the essential commands for the script..."
for file in "$PACKAGES" ; do
  if [ ! -f "$file" ] ; then
    echo "[ERROR] File not found: \"$file\""
    return 3
  fi
done

return 0
}

#-----------------------------------------------------------
function get_linux_distro(){

LINUXDISTRO=UNKNOWN

grep "CentOS" /etc/redhat-release > /dev/null 2>&1 && LINUXDISTRO=CENTOS
grep "Red Hat" /etc/redhat-release > /dev/null 2>&1 && LINUXDISTRO=REDHAT
grep "Debian" /etc/issue > /dev/null 2>&1 && LINUXDISTRO=DEBIAN
grep "Ubuntu" /etc/issue > /dev/null 2>&1 && LINUXDISTRO=UBUNTU

echo $LINUXDISTRO
}

#------------------------------------------------------------
function test_distro_suport(){

echo "[INFO] Testing script compatibility with distro..."

case "$LINUXDISTRO" in
  CENTOS|REDHAT|DEBIAN|UBUNTU)
    echo "[INFO] Support OK: $LINUXDISTRO"
  ;;
  *)
    echo "[ERROR] This script is not ready to run in the distro $LINUXDISTRO."
    exit 5
  ;;
esac
}

#-----------------------------------------------
#-----------------------------------------------
# MAIN
#-----------------------------------------------
#-----------------------------------------------

# Declaracao de variaveis
PACKAGES="wget openssl keytool"
BINARIES="/usr/bin/wget /usr/bin/openssl /usr/bin/keytool"
CMDLINE=$(readlink --canonicalize --no-newline "$BASH_SOURCE")
PROGFILENAME=$(basename "$BASH_SOURCE")
PROGDIRNAME=$(dirname $(readlink -f "$BASH_SOURCE"))
LINUXDISTRO=$(get_linux_distro)
DATA=`date +%Y%m%d_%H-%M`

#Variaveis defaults caso estejam vazias
PT_certs_dir=${PT_certs_dir:-'/etc/sslfree'}
PT_keystore_file=${PT_keystore_file:-'/etc/sslfree/keystore.jks'}
PT_cacerts_file=${PT_cacerts_file:-'/etc/sslfree/cacerts.jks'}
PT_download_ca_cert=${PT_download_ca_cert:-'https://192.168.0.1/cert/ca_bundle.crt'}
PT_ca_cert=${PT_ca_cert:-'ca_bundle.crt'}
PT_download_host_cert_key=${PT_download_host_cert_key:-'https://192.168.0.1/cert/private.key'}
PT_host_cert_key=${PT_host_cert_key:-'private.key'}
PT_download_host_cert_crt=${PT_download_host_cert_crt:-'https://192.168.0.1/cert/certificate.crt'}
PT_host_cert_crt=${PT_host_cert_crt:-'certificate.crt'}
PT_cert_alias=${PT_cert_alias:-'sslfree'}
PT_host_cert_pass=${PT_host_cert_pass:-''}
PT_ca_cert_alias=${PT_ca_cert_alias:-'ca_sslfree'}
PT_java_cacert=${PT_java_cacert:-'/usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts'}
PT_keystore_pass_default=${PT_keystore_pass_default:-'changeit'}
PT_keystore_pass=${PT_keystore_pass:-'changeit'}
#------------------------------------------------------------

# Detecta se eh um usuario com poderes de root que esta executando o script
#if [ $(isroot) = NO ] ; then
#  echo "voce deve ser root para executar este script."
#  echo "execute o comando \"sudo $CMDLINE\""
#  exit 4
#fi

# Detecta se a distro GNU/Linux eh suportada
test_distro_suport

# Checa os comandos essenciais a execucao do script
if ! check_essential_commands $BINARIES ; then
  install_essential_packages $PACKAGES
  check_essential_commands $BINARIES|| exit 3
fi

# Backp do diretorio de certificados
sudo mkdir -p "$PT_certs_dir"
sudo cp -R "$PT_certs_dir" "$PT_certs_dir"-backup-$DATA;

# Download dos certificados
echo "[INFO] Downloading the certificates..."

sudo wget --no-check-certificate -q "$PT_download_ca_cert" \
  -O "$PT_certs_dir/$PT_ca_cert"

sudo wget --no-check-certificate -q "$PT_download_host_cert_key" \
  -O "$PT_certs_dir/$PT_host_cert_key"

sudo wget --no-check-certificate -q "$PT_download_host_cert_crt" \
  -O "$PT_certs_dir/$PT_host_cert_crt"

echo "[INFO] Verifying that the certificates exist..."

sudo chmod -R 755 "$PT_certs_dir"

if [ -f "$PT_certs_dir/$PT_ca_cert" ] ; then
  if [ -z "$PT_certs_dir/$PT_ca_cert" ] ; then
    echo "[ERROR] File empty: '$PT_certs_dir/$PT_ca_cert'"
    exit 15
  fi
else
  echo "[ERROR] File not found: '$PT_certs_dir/$PT_ca_cert'"
  exit 14
fi

if [ -f "$PT_certs_dir/$PT_host_cert_key" ] ; then
  if [ -z "$PT_certs_dir/$PT_host_cert_key" ] ; then
    echo "[ERROR] File empty: '$PT_certs_dir/$PT_host_cert_key'"
    exit 17
  fi
else
  echo "[ERROR] File not found: '$PT_certs_dir/$PT_host_cert_key'"
  exit 16
fi

if [ -f "$PT_certs_dir/$PT_host_cert_crt" ] ; then
  if [ -z "$PT_certs_dir/$PT_host_cert_crt" ] ; then
    echo "[ERROR] File empty: '$PT_certs_dir/$PT_host_cert_crt'"
    exit 19
  fi
else
  echo "[ERROR] File not found: '$PT_certs_dir/$PT_host_cert_crt'"
  exit 18
fi

if [ -f "$PT_keystore_file" ] ; then
  if [ ! -z "$PT_keystore_file" ] ; then
    # Removendo o certificado caso ja exista
    if sudo keytool -list -keystore "$PT_keystore_file" -alias "$PT_cert_alias" \
      -v -storepass "$PT_keystore_pass" -noprompt > /dev/null 2>&1; then

        sudo keytool -delete -keystore "$PT_keystore_file" -alias "$PT_cert_alias" \
          -storepass "$PT_keystore_pass" -noprompt > /dev/null 2>&1;
    fi
  else
    echo "[ERROR] File empty: '$PT_keystore_file'"
    exit 7
  fi
#else
#  echo "[ERROR] File not found: '$PT_keystore_file'"
#  exit 6
fi

echo "[INFO] Deploying the certificates in '$PT_certs_dir'..."

# Adicionando o certificado no keystore
sudo openssl pkcs12 -export -name "$PT_cert_alias" -in "$PT_certs_dir/$PT_host_cert_crt" \
  -inkey "$PT_certs_dir/$PT_host_cert_key" -out "$PT_certs_dir/keystore.p12" -password pass:"$PT_host_cert_pass"

sudo keytool -importkeystore -destkeystore "$PT_keystore_file" \
  -srckeystore "$PT_certs_dir/keystore.p12" -srcstoretype pkcs12 -alias "$PT_cert_alias" \
  -deststorepass "$PT_keystore_pass" -srcstorepass "$PT_host_cert_pass"

# Alterando a senha da chave privada para ser igual a do keystore.
sudo keytool -keypasswd -keypass "$PT_host_cert_pass" -alias "$PT_cert_alias" \
  -keystore "$PT_keystore_file" -storepass "$PT_keystore_pass" \
  -new "$PT_keystore_pass"

if [ -f "$PT_cacerts_file" ] ; then
  if [ ! -z "$PT_cacerts_file" ] ; then
    # Removendo o certificado caso ja exista
    if sudo keytool -list -keystore "$PT_cacerts_file" -alias "$PT_ca_cert_alias" \
      -v -storepass "$PT_keystore_pass" -noprompt > /dev/null 2>&1; then

        sudo keytool -delete -keystore "$PT_cacerts_file" -alias "$PT_ca_cert_alias" \
          -storepass "$PT_keystore_pass" -noprompt > /dev/null 2>&1
    fi
  else
    echo "[ERROR] File empty: '$PT_cacerts_file'"
    exit 9
  fi
#else
#  echo "[ERROR] File not found: '$PT_cacerts_file'"
#  exit 8
fi

echo "[INFO] Deploying the CA certificates in '$PT_certs_dir'..."

# Adicionando o certificado do CA no cacerts
sudo keytool -import -v -trustcacerts -alias "$PT_ca_cert_alias" -file "$PT_certs_dir/$PT_ca_cert" \
  -keystore "$PT_cacerts_file" -storepass "$PT_keystore_pass" -noprompt

# Adicionando o certificado do trustore do Java
sudo cp -R "$PT_java_cacert" "$PT_java_cacert"-backup-$DATA

if [ -f "$PT_java_cacert" ] ; then
  if [ ! -z "$PT_java_cacert" ] ; then
    # Removendo o certificado caso ja exista
    if sudo keytool -list -keystore "$PT_java_cacert" -alias "$PT_ca_cert_alias" \
      -v -storepass "$PT_keystore_pass_default" -noprompt > /dev/null 2>&1; then

        sudo keytool -delete -keystore "$PT_java_cacert" -alias "$PT_ca_cert_alias" \
          -storepass "$PT_keystore_pass_default" -noprompt > /dev/null 2>&1
    fi
  else
    echo "[ERROR] File empty: '$PT_java_cacert'"
    exit 11
  fi
else
  echo "[ERROR] File not found: '$PT_java_cacert'"
  exit 10
fi

echo "[INFO] Deploying the CA certificate in '$PT_java_cacert'..."
sudo keytool -import -v -trustcacerts -alias "$PT_ca_cert_alias" \
  -file "$PT_certs_dir/$PT_ca_cert" -keystore "$PT_java_cacert" \
  -storepass "$PT_keystore_pass_default" -noprompt

if [ -f "$PT_java_cacert" ] ; then
  if [ ! -z "$PT_java_cacert" ] ; then
    # Removendo o certificado caso ja exista
    if sudo keytool -list -keystore "$PT_java_cacert" -alias "$PT_cert_alias" \
      -v -storepass "$PT_keystore_pass_default" -noprompt > /dev/null 2>&1; then

        sudo keytool -delete -keystore "$PT_java_cacert" -alias "$PT_cert_alias" \
          -storepass "$PT_keystore_pass_default" -noprompt > /dev/null 2>&1
    fi
	else
    echo "[ERROR] File empty: '$PT_java_cacert'"
    exit 11
  fi
else
  echo "[ERROR] File not found: '$PT_java_cacert'"
  exit 10
fi

echo "[INFO] Deploying the certificate in '$PT_java_cacert'..."

sudo keytool -import -v -trustcacerts -alias "$PT_cert_alias" \
  -file "$PT_certs_dir/$PT_host_cert_crt" -keystore "$PT_java_cacert" \
  -storepass "$PT_keystore_pass_default" -noprompt

# Ajustando as permissoes de acesso
echo "[INFO] Setting permissions for '$PT_certs_dir' directory access..."

sudo chown -R root:root "$PT_certs_dir"
sudo chmod -R 755 "$PT_certs_dir"
sudo chmod -R 750 "$PT_certs_dir/$PT_host_cert_key";
