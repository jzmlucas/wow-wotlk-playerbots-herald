# WoW WotLK 3.3.5a Self-Host com Playerbots e Herald

Guia para montar no Windows um reino PvE local de Wrath of the Lich King 3.3.5a, com Playerbots, MultiBot, Dungeon Clear e o addon Herald. O instalador baixa as fontes em revisões fixadas, compila o servidor, prepara os bancos e configura os addons.

> **Você precisa obter o cliente do jogo separadamente.** Este repositório não fornece, hospeda nem baixa o World of Warcraft. Use uma cópia sua do cliente WotLK 3.3.5a build 12340. Antes de começar, confirme que a pasta do cliente contém `Wow.exe` e a pasta `Data`. O kit lê uma cópia temporária de `Data` para extrair os arquivos do servidor e preserva os arquivos originais do cliente.

## Requisitos

- Windows 10 ou 11.
- Cliente próprio WoW WotLK 3.3.5a, build 12340.
- Git for Windows.
- SDK .NET 9 para abrir o launcher gráfico a partir do código em um clone limpo.
- Visual Studio Community 2022 com **Desenvolvimento para desktop com C++**.
- CMake, MySQL 8.4 LTS, OpenSSL 3.x x64 e Boost 1.78–1.83.
- Espaço em disco e memória para compilar e gerar mapas, VMAPs e MMAPs. A extração de MMAPs pode levar bastante tempo.

O guia completo para instalar e configurar as dependências está em [Preparar o Windows](docs/01-preparar-o-windows.md). Se tiver pouca memória ou CPU, siga o guia para reduzir a quantidade de bots antes de iniciar.

## Instalação passo a passo

### 1. Obtenha o cliente à parte

Instale ou localize por conta própria uma cópia do cliente WotLK 3.3.5a build 12340. Não coloque o cliente dentro deste repositório. Anote o caminho completo da pasta que contém `Wow.exe` e `Data`, por exemplo:

```text
D:\Jogos\World of Warcraft
```

O kit não altera os dados originais do cliente. Mais detalhes sobre dados e distribuição estão em [Downloads, dados e licenças](docs/05-downloads-e-licencas.md).

### 2. Instale as dependências do Windows

Instale os programas listados em [Preparar o Windows](docs/01-preparar-o-windows.md). Configure `BOOST_ROOT` para a pasta do Boost e `OPENSSL_ROOT_DIR` para a pasta do OpenSSL. O MySQL Client e o servidor precisam estar disponíveis no `PATH`.

### 3. Baixe este kit

Clone ou baixe este repositório. Depois da extração, abra a pasta do projeto.

```powershell
git clone https://github.com/jzmlucas/wow-wotlk-playerbots-herald.git
cd wow-wotlk-playerbots-herald
```

### 4. Execute o launcher gráfico

Dê dois cliques em `Abrir-SoloRealm.vbs`. Em um clone limpo, o launcher gráfico atual é compilado a partir do projeto incluído (requer o SDK .NET 9); depois selecione a pasta do cliente e clique em **Instalação completa**. O launcher mostra os registros e o progresso disponível dentro da própria interface, sem deixar uma janela de terminal aberta.

O instalador verifica dependências e, em seguida:

1. Baixa o AzerothCore Playerbots e os módulos nas revisões fixadas no repositório.
2. Aplica o patch do Herald ao módulo Playerbots.
3. Compila o servidor e as ferramentas de extração.
4. Prepara o MySQL local e os bancos do reino.
5. Copia temporariamente os dados do cliente e gera os arquivos necessários ao servidor.
6. Cria as configurações do reino e instala MultiBot, Dungeon Clear, AltBot e Herald no cliente indicado.
7. Confere se o perfil instalado corresponde às configurações do kit.

A primeira compilação e a extração de mapas podem demorar. Mantenha o computador ligado até o launcher informar que terminou. Se ocorrer um erro, consulte [Baixar fontes e compilar](docs/02-instalar-e-compilar.md) e a aba **Logs**. A documentação completa do launcher está em [Launcher gráfico SoloRealm](docs/07-launcher-grafico.md).

### 5. Inicie o reino e crie sua conta

Depois da instalação, use **Iniciar servidor** na aba **Início** do launcher.

No console do `worldserver`, crie uma conta normal:

```text
.account create SEU_LOGIN SUA_SENHA
```

Substitua os exemplos por suas credenciais. Não use comandos para conceder nível de GM à conta de jogo.

### 6. Aponte o cliente para o reino local

No cliente, faça uma cópia de segurança de `Data/<idioma>/realmlist.wtf` e configure o realmlist local:

```text
set realmlist 127.0.0.1
```

Abra o cliente 3.3.5a, entre com a conta que criou, selecione **Reino Local** e crie seu personagem. O servidor fica restrito ao próprio PC; o kit não abre portas no firewall nem no roteador. Para desligar, use o procedimento de [configurar e jogar](docs/03-configurar-e-jogar.md).

## Configuração incluída

- Reino PvE local em `127.0.0.1`, conteúdo WotLK até o nível 80.
- Perfil inicial com XP de jogador 7x, drop de itens 4x, dinheiro de loot 10x e dinheiro de missões 10x; ajuste em **Configurações** no launcher.
- Perfil com meta de 1.000 bots aleatórios, níveis de 1 a 80, quests/RPG, conversa e LFG habilitados.
- MultiBot e AltBot para interagir com bots; Dungeon Clear para dungeons com o jogador no grupo.
- Herald WotLK com botão de águia na minimapa.
- Teletransporte pelo NPC em Stormwind ou pelo addon Solo Realm Addons com `/teleport` e atalho configurável.
- Loja do reino por gold, com 348 glifos e milhares de montarias, mascotes, bolsas, consumíveis e materiais; preços-base em cobre, prévia no addon Solo Realm Addons, `/shop`, atalho configurável, NPCs nas capitais e botão **Loja de Ouro** no menu `Esc`.
- Scripts de inicialização, encerramento, backup e atualização manual.
- Launcher gráfico Windows para executar instalação, compilação, manutenção e acompanhar logs.

A quantidade e proporção de bots são alvos de configuração; a população efetiva varia conforme o tempo de atividade. Veja [Herald WotLK](docs/06-herald-wotlk.md) e [Operação, backup e atualização](docs/04-operar-e-proteger-dados.md).

## Launcher, loja por gold e teletransporte

### Launcher SoloRealm

Abra `Abrir-SoloRealm.vbs` para usar o **SoloRealm Control Center**. O script abre o executável gráfico compilado quando ele está presente; em um clone sem binários, compila e inicia o projeto `launcher/SoloRealm.Desktop` com o SDK .NET 9. Na primeira execução, selecione a pasta do cliente WotLK que contém `Wow.exe` e `Data`.

- **Início** mostra o estado das portas locais do MySQL, authserver e worldserver. Também permite iniciar o reino, executar a instalação completa, abrir o cliente, consultar o procedimento de encerramento, criar backup e abrir os logs.
- **Instalação e manutenção** reúne as etapas individuais: verificar dependências, baixar fontes, compilar, extrair mapas, configurar o servidor e o MySQL, atualizar bancos, configurar o reino, instalar addons, validar o perfil e encerrar o MySQL.
- **Logs** mostra as mensagens da tarefa ativa e o estado de conclusão. Cada operação gera um arquivo em `launcher/logs`; quando não há percentual fornecido pelo script, a barra fica animada. Os consoles do `authserver` e `worldserver` são abertos separadamente e permanecem visíveis para acompanhar o servidor.

Use **Instalação completa** para preparar o ambiente. Depois que terminar, use **Iniciar servidor**. Para fazer backup consistente, encerre primeiro os servidores; para desligá-los, execute `server shutdown 1` no console do worldserver, feche o authserver e só então use **Encerrar MySQL**.

Veja o [guia do launcher](docs/07-launcher-grafico.md) e a descrição de [cada botão](docs/08-guia-dos-botoes-do-launcher.md).

### Loja de Ouro

A loja usa o **gold do personagem**, sem moeda premium. Abra com `/shop`, com a tecla configurável em **Teclas → Solo Realm Addons**, pelo botão **Loja de Ouro** no menu `Esc` ou conversando com o Mercador do Reino nas capitais.

As categorias incluem glifos, montarias terrestres, voadoras e raras, mascotes, bolsas, consumíveis, materiais de profissão e armas lendárias. Use os filtros de classe e nível para encontrar itens compatíveis; por padrão, a loja usa a classe e o nível do personagem. Os itens com preço de vendedor usam o preço-base do jogo em cobre; itens sem esse preço têm estimativas por categoria e raridade. A loja mostra ouro, prata e cobre. Selecionar um produto apenas mostra sua informação e prévia visual; isso não equipa nem compra o item. A compra ocorre ao clicar em **Comprar**. O servidor confere o preço, o saldo e o espaço na bolsa e entrega o item ao personagem. Os comandos são registrados para personagens com permissão normal de jogador; não é necessária uma conta GM.

Instale os addons pela opção **Instalar addons** no launcher e reinicie o cliente para carregá-los.

### Teletransportes

Abra o menu com `/teleport`, pelo botão **Teletransportes** no menu `Esc` ou configure uma tecla em **Teclas → Solo Realm Addons**. O menu organiza destinos em Reinos do Leste, Kalimdor, Terralém e Nortúndria. Também é possível usar o NPC de teletransporte em Stormwind.

Os comandos são atendidos pelo servidor para personagens com permissão normal de jogador. O nível mínimo aparece junto aos destinos que exigem progressão; o servidor também pode recusar a viagem durante combate, voo, morte ou outro teletransporte. Instale o addon pela opção **Instalar addons** no launcher e reinicie o cliente.

## Créditos

Este kit usa como base o projeto **[AzerothCore](https://www.azerothcore.org/)** e o fork **[AzerothCore Playerbots](https://github.com/mod-playerbots/azerothcore-wotlk)**, mantido pela comunidade do mod-playerbots. Créditos também aos contribuidores do [mod-playerbots](https://github.com/mod-playerbots/mod-playerbots) e aos autores dos módulos e addons identificados em [Terceiros e licenças](THIRD-PARTY-NOTICES.md).

O kit e o addon Herald são projetos comunitários independentes, sem afiliação com a Blizzard Entertainment. Consulte os avisos de licença antes de redistribuir ou modificar componentes de terceiros.

## Documentação

- [Addons e hospedagem local](addons/README.md)
- [Preparar o Windows](docs/01-preparar-o-windows.md)
- [Baixar fontes e compilar](docs/02-instalar-e-compilar.md)
- [Configurar e jogar](docs/03-configurar-e-jogar.md)
- [Operação, backup e atualização](docs/04-operar-e-proteger-dados.md)
- [Downloads, dados e licenças](docs/05-downloads-e-licencas.md)
- [Herald WotLK](docs/06-herald-wotlk.md)
- [Launcher gráfico SoloRealm](docs/07-launcher-grafico.md)
- [Guia dos botões do launcher](docs/08-guia-dos-botoes-do-launcher.md)
