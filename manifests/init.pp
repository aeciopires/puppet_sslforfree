# Class: puppet_sslforfree
#
#-------------------------------------------------------
# author: Aecio Pires <aeciopires@gmail.com>
#-------------------------------------------------------
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
# Requires:
#   Veja a lista de dependencias no arquivo README
#   See the list of dependencies in the README file
#
# Sample Usage:
#
#   include puppet_sslforfree
#
class puppet_sslforfree(

  #------------------------------------
  # ATENCAO! As variaveis referenciadas sao usadas neste manifest e/ou nos
  #   arquivos de templates.
  # ATTENTION! How referenced variables are used in this document and / or
  #   template files.
  #------------------------------------

  $tmp_dir                = $puppet_sslforfree::params::tmp_dir,
  $download_certificate   = $puppet_sslforfree::params::download_certificate,
  $download_ca_cert       = $puppet_sslforfree::params::download_ca_cert,
  $download_host_cert_key = $puppet_sslforfree::params::download_host_cert_key,
  $download_host_cert_crt = $puppet_sslforfree::params::download_host_cert_crt,
  $host_cert_key          = $puppet_sslforfree::params::host_cert_key,
  $host_cert_crt          = $puppet_sslforfree::params::host_cert_crt,
  $ca_cert                = $puppet_sslforfree::params::ca_cert,
  $certs_dir              = $puppet_sslforfree::params::certs_dir,

  ) inherits puppet_sslforfree::params {

  #----------------------DEPENDENCIAS DE MODULOS E CLASSES -------------------#
  include puppet_sslforfree::check_space
  include puppet_sslforfree::certificate_sslforfree
  #---------------------------------------------------------------------------#

  file { $certs_dir:
    ensure  => 'directory',
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    recurse => true,
  }

  #Criando um recuso virtual do tipo Package para evitar erro de duplicacao de
  #declaracao com outros modulos
  @package{[
    'wget',
    'openssl', ]:
    ensure => installed,
  }

  # Realizando o recurso virtual
  realize(Package['wget'],
          Package['openssl'],
  )

  if $download_certificate {
    exec { 'download_certificate':
      command  => "true; \
        cp -R ${certs_dir} ${certs_dir}_backup_$(date +%Y%m%d_%H%M); \
        cd ${certs_dir}/; \

        wget --no-check-certificate -q ${download_ca_cert} \
          -O ${certs_dir}/${ca_cert}; \
        wget --no-check-certificate -q ${download_host_cert_key} \
          -O ${certs_dir}/${host_cert_key}; \
        wget --no-check-certificate -q ${download_host_cert_crt} \
          -O ${certs_dir}/${host_cert_crt}; \
        cd - ; ",
      provider => 'shell',
      path     => ['/usr/local/sbin', '/usr/local/bin','/usr/sbin','/usr/bin',
        '/sbin','/bin'],
      timeout  => '14400', #equivalente a 4 horas
      before   => [ Exec['certificate_jks'], Exec['add_certificate_in_java'], ],
      require  => [ File[$certs_dir], Package['wget'], ],
    }
  }
  else{

    file { "${certs_dir}/${ca_cert}":
      ensure  => file,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/puppet_sslforfree/certs_sslforfree/ca_bundle.crt',
      require => File[$certs_dir],
    }

    file { "${certs_dir}/${host_cert_crt}":
      ensure  => file,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/puppet_sslforfree/certs_sslforfree/certificate.crt',
      require => File[$certs_dir],
    }

    file { "${certs_dir}/${host_cert_key}":
      ensure  => file,
      mode    => '0750',
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/puppet_sslforfree/certs_sslforfree/private.key',
      require => File[$certs_dir],
    }
  }
}
