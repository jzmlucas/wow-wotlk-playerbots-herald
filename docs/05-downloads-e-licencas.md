# 5. Downloads, fontes e arquivos do cliente

## Fontes baixadas pelo kit

O arquivo `config/fontes.json` lista os repositórios Git oficiais usados pelo instalador:

- [Fork AzerothCore Playerbot](https://github.com/mod-playerbots/azerothcore-wotlk), branch `Playerbot`.
- [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots).
- [mod-dungeon-clear](https://github.com/jrad7/mod-dungeon-clear).
- [mod-multibot-bridge](https://github.com/Wishmaster117/mod-multibot-bridge).
- [MultiBot Chatless](https://github.com/Wishmaster117/MultiBot-Chatless).
- [DungeonClear Addon](https://github.com/jrad7/mod-dungeon-clear-addon).
- [AltBot](https://github.com/errordnk/altbot).

As revisões usadas pelo kit estão fixadas em `config/fontes.lock.json`; atualizações são manuais por padrão. A adaptação Herald está versionada como patch contra a revisão fixada do `mod-playerbots`. Os addons de terceiros são baixados em suas próprias revisões e não são incluídos neste repositório.

## Dependências oficiais

- [Git para Windows](https://git-scm.com/download/win)
- [SDK .NET 9](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)
- [CMake](https://cmake.org/download/)
- [MySQL Community Server](https://dev.mysql.com/downloads/mysql/)
- [OpenSSL](https://slproweb.com/products/Win32OpenSSL.html)
- [Boost](https://www.boost.org/users/download/)

O instalador verifica a presença e apresenta links; não baixa installers de terceiros nem executa instalação privilegiada automaticamente.

## Dados do jogo

AzerothCore não distribui cliente. O kit não contém cliente WoW, executáveis, mapas, DBCs ou arquivos extraídos. Cada administrador fornece seu cliente WotLK 3.3.5a build 12340 e gera os próprios dados. Use somente arquivos a que tenha acesso legítimo. O extrator lê uma cópia temporária do `Data` e do `Wow.exe`; ele não sobrescreve os arquivos do cliente. Não publique os arquivos `Data`, mapas, DBC, VMAP ou MMAP gerados.
