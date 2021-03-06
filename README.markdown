# puppet_sslforfree #

[Português]: #português
[Requisitos]: #requisitos
[Instruções]: #instruções-de-uso
[Hiera]: #hiera
[English]: #english
[Requirements]: #requirements
[Instructions]: #instructions
[Hiera]: #hiera
[Parameters]: #parameters
[Developers]: #developers
[License]: #license

#### Menu

1. [Português][Português]
    - [Requisitos][requisitos]
    - [Instruções de uso][Instruções]
    - [Hiera][Hiera]
    - [TASK_README.md](https://github.com/aeciopires/puppet_sslforfree/blob/master/TASK_README.md)
2. [English][English]
    - [Requirements][requirements]
    - [Instructions][instructions]
    - [Hiera][Hiera]
    - [TASK_README.md](https://github.com/aeciopires/puppet_sslforfree/blob/master/TASK_README.md)
3. [Parameters][Parameters]
4. [Developers][Developers]
5. [CHANGELOG.md](https://github.com/aeciopires/puppet_sslforfree/blob/master/CHANGELOG.md)
6. [License][License]

# Português

Este é o modulo *puppet_sslforfree*.

Instala e gerencia o certificado assinado pelos sites:

- https://www.sslforfree.com
- https://zerossl.com
- https://gethttpsforfree.com

Também cria o certificado no formato JKS.

Para aprender mais sobre o uso do Puppet, recomendo a leitura do livro que
publiquei pela Novatec:

https://novatec.com.br/livros/puppet

Veja também os links que estão nesta página:

http://blog.aeciopires.com/primeiros-passos-com-o-puppet

## Requisitos

1. Acesse um dos sites anteriores e gere o certificado de host ou wildcard conforme
as instruções disponíveis. Ambos usam a API do Let's encrypt para assinar os
certificados válidos e gratuitos com duração de 90 dias.
2. Puppet 4.x ou superior
3. Sistema operacional: Debian 8.x, 9.x, CentOS 6.x, 7.x, Red Hat 6.x e
7.x, Ubuntu 14.04, 16.04 e 18.04.
4. Instalar o pacote ``keytool`` obtido junto com o Java. Este módulo não
instala o Java.

Observações:

- Para atualizar/renovar o certificado basta mudar o valor do parâmetro
``overwrite_certificate`` para ``true`` e informar a nova URL de download em
``cert_download_url_base``, após gerar o novo certificado e salvá-lo em um
servidor web.
- Este módulo não configura os serviços para usar o certificado. Isso
deve ser feito por outro módulo Puppet ou manualmente.

## Instruções de Uso

Baixe o módulo em:
**https://github.com/aeciopires/puppet_sslforfree/releases**

Descompacte o pacote e copiar o diretório **puppet_sslforfree** para a
máquina **puppetserver**.

Na máquina **puppetserver**, mova o diretório **puppet_sslforfree**
para o diretório de módulos, por exemplo:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/modules/**. Onde ``NAME_ENVIRONMENT`` deve ser trocado pelo nome do environment que você
quer usar no PuppetServer.

Edite o aquivo
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/manifests/site.pp**
e definir quais hosts usarão o módulo, conforme o exemplo abaixo. Exemplo
 da configuração do arquivo ``site.pp``.

~~~ puppet
node node1.domain.com.br {
    include puppet_sslforfree
}
~~~

Execute o Puppet Agent no servidor ``node1.domain.com.br``.

~~~ bash
puppet agent -t
~~~

## Hiera

O módulo *puppet_sslforfree* instala e configura o certificado com as
configurações definidas em parâmetros ou variáveis declaradas no
manifest **params.pp**.

Algumas variáveis possuem valores customizados de acordo com o servidor.
Estes valores são obtidos através do Hiera (com dados armazenados em
arquivos do tipo "*.yaml").

Abaixo está um exemplo do arquivo de configuração do Hiera, que deve
ficar localizado em:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hiera.yaml**

~~~ puppet
---
version: 5
defaults:
  datadir: hieradata
  data_hash: yaml_data
hierarchy:
  - name: "Hosts"
    paths:
      - "host/%{::trusted.certname}.yaml"
      - "host/%{::facts.networking.fqdn}.yaml"
      - "host/%{::facts.networking.hostname}.yaml"

  - name: "Dominios"
    paths:
      - "domain/%{::trusted.domain}.yaml"
      - "domain/%{::domain}.yaml"

  - name: "Dados comuns"
    path: "common.yaml"
~~~

Dessa forma, o Hiera buscará, prioritariamente, os valores definidos nas
variáveis de host (sobrepondo os valores de variáveis de mesmo nome
definidas por domínio). Estas variáveis devem ficar em arquivos como esse:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/host/node1.domain.com.br.yaml**.

Caso não sejam definidos valores para variáveis nos arquivos de hosts,
o Hiera buscará valores definidos em variáveis de domínio. As variáveis
de domínio devem ficar em arquivos como esse:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/domain/domain.com.br.yaml**.

As variáveis definidas no arquivo
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/common.yaml**,
só serão aplicadas em último caso.

Mesmo que nenhum destes arquivos existam, serão aplicados os valores padrão
definidos na classe **params.pp**.

### Exemplo do arquivo .yaml

~~~ puppet
#---------------------
#BEGIN
#---------------------

#Espaco requerido: 2 MB ou 2.000.000 bytes
space_required: 2000000
tmp_dir: '/tmp'
manage_certificate_jks: true
overwrite_certificate: false
download_certificate: true
cert_download_url_base: 'https://192.168.0.1/cert'
keytool: '/usr/bin/keytool'
host_cert_key: 'private.key'
host_cert_crt: 'certificate.crt'
ca_cert: 'ca_bundle.crt'
host_cert_pass: ''
cert_alias: 'sslfree'
ca_cert_alias: 'ca_sslfree'
certs_dir: '/etc/sslfree'
java_cacert: '/usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts'

#---------------------
#END
#---------------------
~~~

# English

This is the **puppet_sslforfree** module.

Installs and manages the certificate signed by the sites:

- https://www.sslforfree.com
- https://zerossl.com
- https://gethttpsforfree.com

It also creates the certificate in JKS format.

## Requirements

1. Access one of the sites previous and generate the host or wildcard certificate.
Both use the Let's encrypt API to sign the valid and free certificates with a
duration of 90 days.
2. Puppet 4.x or higher
3. Operating System: Debian 8.x, 9.x, CentOS 6.x, 7.x, Red Hat 6.x and
7.x, Ubuntu 14.04, 16.04 and 18.04.
4. Install the ``keytool`` packages obtained with Java. This module does not
installs Java.

Comments:

- To update/renew the certificate, simply change the value of the parameter
``overwrite_certificate`` to `` true`` and enter the new download URL at
``cert_download_url_base`` after generating the new certificate and save it to
a web server.
- This module does not configure services to use the certificate. You
MUST be done by another Puppet module or manually.

## Instructions

Download the module in:
**https://github.com/aeciopires/puppet_sslforfree/releases**

Unzip the package and copy the **puppet_sslforfree** directory to the
 **puppetserver** machine.

On the **puppetserver** machine, move the directory **puppet_sslforfree**
to the modules directory, for example:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/modules/**. Where ``NAME_ENVIRONMENT`` should be changed by the name of the environment
you want to use in PuppetServer.

Edit the file
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/manifests/site.pp**
and define which hosts will use the module, as shown in the example below.
Example of the configuration of the ``site.pp`` file

~~~ puppet
node node1.domain.com.br {
    include puppet_sslforfree
}
~~~

Run the Puppet Agent on the ``node1.domain.com`` server.

~~~ bash
puppet agent -t
~~~

## Hiera

The **puppet_sslforfree** module installs and configures the certificate with
the settings defined in parameters or variables declared in the manifest
**params.pp**.

Some variables have custom values ​​according to the server.
These values ​​are obtained through Hiera (with data stored in
files of type "* .yaml").

Below is an example of the Hiera configuration file, which should
be located at:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hiera.yaml**

~~~ puppet
---
version: 5
defaults:
  datadir: hieradata
  data_hash: yaml_data
hierarchy:
  - name: "Hosts"
    paths:
      - "host/%{::trusted.certname}.yaml"
      - "host/%{::facts.networking.fqdn}.yaml"
      - "host/%{::facts.networking.hostname}.yaml"

  - name: "Domains"
    paths:
      - "domain/%{::trusted.domain}.yaml"
      - "domain/%{::domain}.yaml"

  - name: "Common"
    path: "common.yaml"
~~~

In this way, Hiera will seek, as a priority, the values ​​defined in the
variables (overlapping variable values ​​of the same name defined by the domain).
These variables should be in files like this:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/host/node1.domain.com.br.yaml**.

If no value is set for variables in the hosts files,
Hiera will look for values ​​defined in domain variables. The variables
domain MUST be in files like this:
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/domain/domain.com.br.yaml**.

The variables defined in the
**/etc/puppetlabs/code/environments/NAME_ENVIRONMENT/hieradata/common.yaml**
file, will only be applied in the latter case.

Even if none of these files exist, the default values ​​defined in the
**params.pp** class will be applied.

### Sample file .yaml

~~~ puppet
#---------------------
#BEGIN
#---------------------

#Space Required: 2 MB or 2.000.000 bytes
space_required: 2000000
tmp_dir: '/tmp'
manage_certificate_jks: true
overwrite_certificate: false
download_certificate: true
cert_download_url_base: 'https://192.168.0.1/cert'
keytool: '/usr/bin/keytool'
host_cert_key: 'private.key'
host_cert_crt: 'certificate.crt'
ca_cert: 'ca_bundle.crt'
host_cert_pass: ''7
cert_alias: 'sslfree'
ca_cert_alias: 'ca_sslfree'
certs_dir: '/etc/sslfree'
java_cacert: '/usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts'

#---------------------
#END
#---------------------
~~~

## Parameters

### space_required

**Description:** Sets the minimum required disk space.

**Data type:** Interger.

**Default value:** 2000000 (in bytes).

### tmp_dir

**Description:** Sets the temporary directory.

**Data type:** String.

**Default value:** /tmp

### manage_certificate_jks

**Description:** If ``true``, it manages the certificate. If ``false`` does
nothing.

**Data type:** Boolean.

**Default value:** true

### overwrite_certificate

**Description:** If ``true``, overwrite the certificate with the same alias
every round of the puppet agent. If ``false``, keep the certificate and to
register the new you must change the alias of the new certificate in the
parameters: ``cert_alias`` and ``ca_cert_alias``.

**Data type:** Boolean.

**Default value:** false

### download_certificate

**Description:** If ``true``, download the certificate from the URL formed by
the concatenation of the parameters: ``$cert_download_url_base/$host_cert_key``,
``$cert_download_url_base/$host_cert_crt`` and
``$cert_download_url_base/$ca_cert``. If ``false``, you must to update the
content of the files in the module directory in ``files/certs_sslfree``.

**Data type:** Boolean.

**Default value:** true

### cert_download_url_base

**Description:** Certificate download base URL.

**Data type:** String.

**Default value:** https://192.168.0.1/cert

### keytool

**Description:** Path of the keytool binary in the operating system. Keytool is
obtained by installing Java. This module does not manage Java installation

**Data type:** String.

**Default value:** /usr/bin/keytool

### host_cert_key

**Description:** Name of the private key file. The name of this file will be
concatenated with the URL entered in the parameter ``cert_download_url_base``.

**Data type:** String.

**Default value:** private.key

### host_cert_crt

**Description:** Name of the certificate file. The name of this file will be
concatenated with the URL entered in the parameter ``cert_download_url_base``.

**Data type:** String.

**Default value:** certificate.crt

### ca_cert

**Description:** Name of the certificate file of the Certificate Authority.
The name of this file will be concatenated with the URL entered in the
parameter ``cert_download_url_base``.

**Data type:** String.

**Default value:** ca_bundle.crt

### host_cert_pass

**Description:** Certificate password.

**Data type:** String.

**Default value:** ' ' (empty)

### cert_alias

**Description:** Certificate alias. This module uses the keytool to create a
repository JKS so that the certificate can be used by applications or
Java application servers.

**Data type:** String.

**Default value:** sslfree

### ca_cert_alias

**Description:** Alias of the Certificate Authority. This module uses the
keytool to create a repository JKS so that the certificate can be used
by applications or Java application servers.

**Data type:** String.

**Default value:** ca_sslfree

### certs_dir

**Description:** Directory in which the certificates will be stored.

**Data type:** String.

**Default value:** /etc/sslfree

### java_cacert

**Description:** Repository JKS of the Java for storing Certificate Authority
certificates. See https://en.wikipedia.org/wiki/Keystore.

**Data type:** String.

**Default value:** /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts

## Developers

developer: Aecio dos Santos Pires<br>
mail: aeciopires at gmail.com<br>

## License

Apache 2.0 2018 Aécio dos Santos Pires
