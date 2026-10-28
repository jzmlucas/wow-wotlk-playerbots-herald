# 1. Preparar o Windows

O build oficial para Windows usa Visual Studio 2022, CMake, Boost, OpenSSL, MySQL e Git. O guia do Playerbots recomenda Boost entre 1.78 e 1.83 para evitar incompatibilidade conhecida com Boost 1.87+. Consulte os links oficiais abaixo para conferir versões e passos atuais.

## Dependências

Instale e configure:

1. Windows 10 ou superior.
2. Git para Windows.
3. SDK .NET 9 para compilar o launcher gráfico no primeiro uso de um clone limpo.
4. Visual Studio Community 2022 com a carga de trabalho **Desktop development with C++**.
5. CMake para Windows x64.
6. MySQL 8.4 LTS Community Server e os arquivos de desenvolvimento.
7. OpenSSL 3.x x64.
8. Boost para Visual Studio 2022, x64, versão compatível com o Playerbots; defina `BOOST_ROOT` sem barra final.

Evite MySQL 26.x e versões que a documentação do AzerothCore marque como não suportadas. O script `scripts/00-verificar-pre-requisitos.ps1` verifica comandos e caminhos comuns; ele não instala nem altera componentes do Windows.

## Recursos locais

A compilação usa no máximo quatro processos internos e, por padrão, uma tarefa CMake em paralelo. O perfil configura seis threads de mapa e uma meta de 1.000 bots aleatórios, distribuídos entre níveis 1 e 80. Essa população pode exigir bastante CPU e memória; ajuste `Playerbots.MinRandomBots` e `Playerbots.MaxRandomBots` em `config/playerbots-overrides.conf` para reduzir a meta em computadores com recursos limitados.

## Limites de rede e dados

- O perfil padrão escuta somente em `127.0.0.1`; não crie regras de firewall nem redirecionamento no roteador.
- Tenha uma cópia válida do cliente 3.3.5a (build 12340). O kit não baixa nem inclui o cliente.
- As ferramentas extraem dados para `servidor/run/Data` usando uma cópia temporária do diretório `Data`; a pasta original do cliente não é alterada.

## Referências oficiais

- [Requisitos Windows AzerothCore](https://www.azerothcore.org/wiki/windows-requirements)
- [Instalação Windows AzerothCore](https://www.azerothcore.org/wiki/windows-core-installation)
- [Instalação Playerbots](https://github.com/mod-playerbots/mod-playerbots/wiki/Installation-Guide)
