# Class: certificate_sslforfree
#
# Parameters: none
#
# Actions:
#   Instala e gerencia o certificado assinado pelos sites abaixo:
#     https://www.sslforfree.com
#     https://gethttpsforfree.com
#     https://zerossl.com
#     Tambem cria o certificado no formato JKS.
#   Install and manage the certificate singed by the sites:
#     https://www.sslforfree.com
#     https://gethttpsforfree.com
#     https://zerossl.com
#   Also creates the certificate in JKS format.
#
# Sample Usage:
#
#   include puppet_sslforfree::certificate_sslforfree
#
class puppet_sslforfree::certificate_sslforfree(

  #------------------------------------
  # ATENCAO! As variaveis referenciadas sao usadas neste manifest e/ou nos
  #   arquivos de templates.
  # ATTENTION! How referenced variables are used in this document and / or
  #   template files.
  #------------------------------------

  $tmp_dir                = $puppet_sslforfree::params::tmp_dir,
  $manage_certificate_jks = $puppet_sslforfree::params::manage_certificate_jks,
  $overwrite_certificate  = $puppet_sslforfree::params::overwrite_certificate,
  $keytool                = $puppet_sslforfree::params::keytool,
  $host_cert_key          = $puppet_sslforfree::params::host_cert_key,
  $host_cert_crt          = $puppet_sslforfree::params::host_cert_crt,
  $ca_cert                = $puppet_sslforfree::params::ca_cert,
  $host_cert_pass         = $puppet_sslforfree::params::host_cert_pass,
  $cert_alias             = $puppet_sslforfree::params::cert_alias,
  $ca_cert_alias          = $puppet_sslforfree::params::ca_cert_alias,
  $keystore_pass_default  = $puppet_sslforfree::params::keystore_pass_default,
  $keystore_pass          = $puppet_sslforfree::params::keystore_pass,
  $certs_dir              = $puppet_sslforfree::params::certs_dir,
  $keystore_file          = $puppet_sslforfree::params::keystore_file,
  $cacerts_file           = $puppet_sslforfree::params::cacerts_file,

  ) inherits puppet_sslforfree::params {

  if $overwrite_certificate {
    exec { 'remove_certificate_keystore_jks':
      command  => "true; \
        ${keytool} -delete -keystore ${keystore_file} -alias ${cert_alias} \
          -storepass ${keystore_pass} -noprompt; ",
      onlyif   => "true; \
        test 0 -eq $(${keytool} -list -keystore ${keystore_file} \
        -alias ${cert_alias} -v -storepass '${keystore_pass}' | grep Exception \
        | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      require  => File[$certs_dir],
      before   => Exec['certificate_jks'],
    }

    exec { 'remove_ca_cacerts_jks':
      command  => "true; \
        ${keytool} -delete -keystore ${cacerts_file} -alias ${ca_cert_alias} \
          -storepass ${keystore_pass} -noprompt; ",
      onlyif   => "true; \
        test 0 -eq $(${keytool} -list -keystore ${cacerts_file} \
        -alias ${ca_cert_alias} -v -storepass '${keystore_pass}' \
        | grep Exception | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      require  => File[$certs_dir],
      before   => Exec['certificate_jks'],
    }

    exec { 'remove_ca_cacerts_java':
      command  => "true; \
        ${keytool} -delete -keystore ${java_cacert} -alias ${ca_cert_alias} \
          -storepass ${keystore_pass_default} -noprompt; ",
      onlyif   => "true; \
        test 0 -eq $(${keytool} -list -keystore ${java_cacert} \
        -alias ${ca_cert_alias} -v -storepass '${keystore_pass_default}' \
        | grep Exception | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      require  => File[$certs_dir],
      before   => Exec['add_certificate_in_java'],
    }

    exec { 'remove_certificate_cacerts_java':
      command  => "true; \
        ${keytool} -delete -keystore ${java_cacert} -alias ${cert_alias} \
          -storepass ${keystore_pass_default} -noprompt; ",
      onlyif   => "true; \
        test 0 -eq $(${keytool} -list -keystore ${java_cacert} \
        -alias ${cert_alias} -v -storepass '${keystore_pass_default}' \
        | grep Exception | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      require  => File[$certs_dir],
      before   => Exec['add_certificate_in_java'],
    }
  }

  if $manage_certificate_jks {
    exec { 'certificate_jks':
      command  => "true; \
        cd ${certs_dir}; \

        openssl pkcs12 -export -name ${cert_alias} -in ${host_cert_crt} \
          -inkey ${host_cert_key} -out keystore.p12 \
          -password pass:'${host_cert_pass}' ; \

        ${keytool} -importkeystore -destkeystore ${keystore_file} \
          -srckeystore keystore.p12 -srcstoretype pkcs12 \
          -alias ${cert_alias} -deststorepass '${keystore_pass}' \
          -srcstorepass '${host_cert_pass}' ; \

        ${keytool} -keypasswd -keypass '${host_cert_pass}' \
          -alias ${cert_alias} -keystore ${keystore_file} \
          -storepass '${keystore_pass}' -new '${keystore_pass}' ; \

        ${keytool} -import -v -trustcacerts -alias ${ca_cert_alias} \
          -file ${ca_cert} -keystore ${cacerts_file} \
          -storepass '${keystore_pass}' -noprompt; \
        cd - ; ",
      onlyif   => "true; \
        test 0 -lt $(${keytool} -list -keystore ${keystore_file} \
        -alias ${cert_alias} -v -storepass '${keystore_pass}' | grep Exception \
        | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      require  => File[$certs_dir],
    }

    #Verificando se o sistema operacional eh suportado
    case $::operatingsystem {
      'centos','redhat': {
        # Variavel referentes ao Java JRE da Oracle
        $java_cacert = $puppet_sslforfree::params::java_cacert
      }
      'debian','ubuntu': {
        # Variavel referentes ao Java JRE da Oracle
        $java_cacert = $puppet_sslforfree::params::java_cacert
      }
      default: {
        fail('[ERROR] S.O NOT supported.')
      }
    }

    #Adicionando o certificado do trustore do Java da Oracle
    exec { 'add_certificate_in_java':
      command  => "true; \
        cp -R ${java_cacert} ${java_cacert}_backup_$(date +%Y%m%d_%H%M); \
        cd ${tmp_dir}/; \

        ${keytool} -import -v -trustcacerts -alias ${ca_cert_alias} \
          -file ${certs_dir}/${ca_cert} -keystore ${java_cacert} \
          -storepass '${keystore_pass_default}' -noprompt; \

        ${keytool} -import -v -trustcacerts -alias ${cert_alias} \
          -file ${certs_dir}/${host_cert_crt} -keystore ${java_cacert} \
          -storepass '${keystore_pass_default}' -noprompt; \
        cd -; ",
      onlyif   => "true; \
        test 0 -lt $(${keytool} -list -keystore ${java_cacert} \
        -alias ${ca_cert_alias} -v -storepass '${keystore_pass_default}' | \
        grep Exception | wc -l)",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
    }
  }
}
