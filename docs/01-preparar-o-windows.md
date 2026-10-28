# 1. Preparar o Windows

> **Compatibilidade: somente Windows 10/11 x64.** Este repositório não oferece instalador nem instruções de compilação para Linux ou macOS.

O launcher detecta as dependências do servidor. Quando encontra um componente ausente, informa o nome e a origem, pergunta se pode continuar, baixa o instalador e abre a instalação para você concluir. A verificação final acontece automaticamente antes do build. O Windows Package Manager (`winget`, incluído no App Installer do Windows) é usado para Git, CMake e OpenSSL. Se `winget` não estiver disponível, instale o App Installer pela Microsoft Store e repita a verificação.

## Componentes verificados

- SDK .NET 9: necessário apenas para abrir o launcher a partir do código em um clone sem executável; baixado da Microsoft e instalado na conta atual do Windows após confirmação.
- Git for Windows: usado para baixar as fontes fixadas do servidor.
- Visual Studio Community 2022 com **Desenvolvimento para desktop com C++**: o launcher baixa o bootstrapper oficial da Microsoft e abre o instalador com o workload correto.
- CMake x64 e OpenSSL 3.x completo x64: detectados e instalados pelo WinGet, com confirmação individual.
- MySQL Community Server 8.4 LTS x64: o ZIP oficial da Oracle é baixado e extraído em `servidor/tools`. É uma cópia portátil privada do kit, não instala serviço global nem sobrescreve outro MySQL.
- Boost 1.83.0, binário x64 para MSVC 14.3: o launcher baixa o instalador e pede que você conclua a instalação. Se não detectar a pasta ao final, abrirá um seletor para você apontar a pasta que contém `boost/version.hpp`. Cada caminho fica salvo na variável de usuário correspondente (`BOOST_ROOT` ou `OPENSSL_ROOT_DIR`).

O SDK .NET baixado pelo launcher fica em `%LOCALAPPDATA%\SoloRealm\dotnet`; os instaladores auxiliares ficam em `%LOCALAPPDATA%\SoloRealm\downloads`. Os arquivos do MySQL são mantidos em `servidor/tools`, caminho ignorado pelo Git.

## Confirmar as dependências

No launcher, abra **Instalação e manutenção → Preparar dependências**. A opção **Instalação completa** executa essa mesma verificação antes de baixar fontes ou compilar. A interface mostra o nome de cada dependência enquanto baixa; confirme cada diálogo para prosseguir e conclua qualquer janela de instalação que o Windows abrir. Se uma instalação precisar de reinicialização ou não terminar, abra o launcher novamente e repita a verificação.

O script `scripts/00-verificar-pre-requisitos.ps1` apenas confere o estado instalado. A rotina interativa de download e instalação é `scripts/00-preparar-dependencias.ps1`.

## Recursos locais e dados

A compilação usa no máximo quatro processos internos e, por padrão, uma tarefa CMake em paralelo. O perfil configura seis threads de mapa e uma meta de 1.000 bots aleatórios. Essa população pode exigir bastante CPU e memória; ajuste `Playerbots.MinRandomBots` e `Playerbots.MaxRandomBots` em `config/playerbots-overrides.conf` para reduzir a meta em computadores com recursos limitados.

- O perfil padrão escuta somente em `127.0.0.1`; não crie regras de firewall nem redirecionamento no roteador.
- Tenha uma cópia própria válida do cliente 3.3.5a (build 12340). O kit não baixa nem inclui o cliente.
- As ferramentas extraem dados para `servidor/run/Data` usando uma cópia temporária do diretório `Data`; a pasta original do cliente não é alterada.

## Referências

- [Requisitos Windows AzerothCore](https://www.azerothcore.org/wiki/windows-requirements)
- [Instalação Windows AzerothCore](https://www.azerothcore.org/wiki/windows-core-installation)
- [Instalação Playerbots](https://github.com/mod-playerbots/mod-playerbots/wiki/Installation-Guide)
- [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)
- [MySQL Community Server 8.4](https://dev.mysql.com/downloads/mysql/8.4.html)
- [Boost 1.83.0](https://www.boost.org/releases/1.83.0/)
