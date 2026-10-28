# Guia dos botões do SoloRealm Control Center

## Configurações

Na aba **Configurações**, as opções ficam organizadas em **Progressão** (XP, drop, dinheiro, reputação e honra), **Criaturas e mundo** (respawn, vida, dano, aggro, durabilidade e voos) e **Bots** (população, níveis, facções, comportamento e equipamentos). Clique em **Salvar perfil** para guardar os valores em `config/perfil-servidor.json`; **Aplicar configuração** também atualiza os arquivos `.conf` do servidor e preserva cópias anteriores em `servidor/config-backups`. Reinicie o `worldserver` para carregar os novos valores. O respawn muda o tempo de retorno das criaturas, mas não acrescenta novos pontos de spawn ao mundo.


Este guia explica os controles exibidos nas abas **Início**, **Instalação e manutenção** e **Logs**. As operações são executadas pelos scripts deste repositório em segundo plano; a aba **Logs** mostra a saída e o resultado.

## Antes de começar

- Para **Instalação completa**, **Extrair mapas e dados** e **Instalar addons**, escolha a pasta do cliente WotLK 3.3.5a em **Selecionar…**. Ela deve conter `Wow.exe` e `Data`. O caminho fica salvo no perfil local do Windows.
- Execute apenas uma operação por vez. Durante a execução, os botões de ação ficam desabilitados.
- A barra de progresso é animada quando a operação não informa um percentual. Ela só mostra percentual ou contagem quando o script fornece esses dados; por isso, pode continuar animada mesmo enquanto o trabalho avança.
- Cada tarefa iniciada pela interface gera um arquivo em `launcher/logs`. Se uma tarefa falhar, a janela informa o código de saída e o caminho do log.

## Aba Início

### Estado dos serviços

Os cartões **MYSQL**, **AUTH SERVER** e **WORLD SERVER** verificam se há uma resposta nas portas locais `3306`, `3724` e `8085`. **ONLINE** significa que a porta respondeu; isso ajuda a acompanhar os serviços, mas não substitui um teste de login dentro do jogo.

### Pasta do cliente e Selecionar…

Escolhe onde está o cliente do jogo. A pasta precisa conter `Wow.exe` e `Data`. O botão abre o seletor de pastas e salva o caminho para as próximas execuções.

### INICIAR SERVIDOR

Executa o script de inicialização. Ele prepara/inicia o MySQL local, verifica executáveis, configurações e dados extraídos, e então abre os consoles do `authserver` e do `worldserver`. Esses consoles ficam visíveis para acompanhar as mensagens do servidor; os logs de inicialização são gravados em `servidor/run/startup-logs`.

Use depois de concluir a instalação e configurar uma conta. Se os serviços já estiverem em execução, a inicialização é recusada para evitar duplicar processos.

### INSTALAÇÃO COMPLETA

Executa a sequência completa: detecta as dependências, informa e pede autorização para baixar/instalar cada componente ausente, valida o ambiente, baixa ou restaura as fontes fixadas, compila o servidor, prepara o MySQL, extrai mapas e dados do cliente, configura servidor e bancos, configura o reino, instala addons e valida o perfil.

É destinada à primeira instalação ou à reconstrução do ambiente. Pode demorar bastante, especialmente na compilação e na geração de MMAPs. Mantenha o computador ligado até o resultado aparecer na aba **Logs**. A extração trabalha sobre uma cópia temporária dos dados e preserva os arquivos originais do cliente.

### ABRIR CLIENTE

Abre `Wow.exe` usando a pasta selecionada. Se o caminho não estiver definido ou não tiver `Wow.exe`, a interface mostra um aviso.

### ENCERRAR SERVIÇOS

Mostra o procedimento de encerramento seguro. No console do `worldserver`, execute `server shutdown 1`; aguarde o worldserver fechar e feche o console do authserver. Depois, use **Encerrar MySQL** na aba de manutenção. Este botão não encerra processos à força.

### CRIAR BACKUP

Cria dumps SQL dos bancos `acore_auth`, `acore_characters`, `acore_world` e `acore_playerbots`, além das configurações e do arquivo de versões fixadas das fontes, quando disponíveis. O backup é salvo em uma pasta datada dentro de `servidor/backups`.

Para manter a consistência, o script exige que `authserver` e `worldserver` estejam encerrados. Os arquivos podem conter configurações privadas do ambiente local; guarde o backup com cuidado.

### ABRIR LOGS

Abre no Explorador a pasta dos logs de inicialização do servidor, se ela existir. Caso contrário, abre `launcher/logs`, onde ficam os registros das tarefas executadas pela interface.

## Aba Instalação e manutenção

### VERIFICAR PRÉ-REQUISITOS

Detecta Git, CMake, MySQL, Boost, OpenSSL e as ferramentas C++ do Visual Studio. Para cada dependência ausente, exibe um aviso, pede autorização, baixa o instalador e abre a instalação. No fim, verifica novamente todos os componentes. O botão e o fluxo de compilação são somente para Windows 10/11 x64.

### BAIXAR / ATUALIZAR FONTES

Obtém os repositórios declarados pelo kit nas revisões fixadas no arquivo de lock. Sem uma opção especial de atualização de pins, restaura as versões já registradas. Não equivale a atualizar tudo para a versão mais recente.

### COMPILAR SERVIDOR

Gera o build do AzerothCore e dos módulos e copia os executáveis e dependências para `servidor/run`. O script calcula automaticamente um paralelismo conservador com base na memória e nos processadores disponíveis. Não inicie a compilação enquanto `authserver` ou `worldserver` estiverem rodando.

### EXTRAIR MAPAS E DADOS

Usa o cliente selecionado para extrair `dbc`, mapas, câmeras, VMAPs e MMAPs exigidos pelo servidor. O processo cria uma área de estágio em `servidor/extracao` e copia os resultados para `servidor/run/Data`. Pode levar bastante tempo; o cliente original é preservado.

### CONFIGURAR SERVIDOR

Prepara os arquivos de configuração do `authserver` e `worldserver` com o perfil local do kit. Antes de alterar as configurações, o script guarda uma cópia datada em `servidor/config-backups`.

### PREPARAR MYSQL

Inicializa ou inicia o MySQL local, vinculado a `127.0.0.1:3306`, e prepara os bancos e o usuário local usados pelo AzerothCore. Se o MySQL já estiver pronto, o script verifica sua disponibilidade e reutiliza as credenciais locais existentes.

### ATUALIZAR BANCOS

Prepara o MySQL e executa `dbimport` para aplicar atualizações dos bancos de autenticação, personagens, mundo e módulos. Aguarde a tarefa terminar e confira o resultado na aba **Logs** antes de iniciar o servidor.

### CONFIGURAR REINO LOCAL

Aplica e confere no banco de autenticação a entrada **Reino Local**, configurada para `127.0.0.1` e para o cliente WotLK 3.3.5a build 12340.

### INSTALAR ADDONS

Copia os addons incluídos e configurados pelo kit para a pasta `Interface/AddOns` do cliente escolhido. Alguns addons vêm das fontes já baixadas pelo kit, então execute **Baixar / atualizar fontes** antes se ainda não tiver feito essa etapa. Depois da cópia, reinicie o cliente para carregá-los.

### VALIDAR CONFIGURAÇÃO

Faz verificações estáticas dos arquivos de configuração do reino, como endereço local, nível máximo e taxas configuradas para o perfil. **Perfil estático validado** confirma os valores dos arquivos; não confirma por si só que o servidor iniciou ou que uma função foi testada dentro do jogo.

### ENCERRAR MYSQL

Encerra o MySQL local usando o comando de desligamento seguro. A interface bloqueia esta ação se detectar as portas do authserver ou worldserver ativas. Primeiro desligue o `worldserver` com `server shutdown 1` e feche o authserver; então tente novamente.

## Aba Logs

### Área de saída

Exibe as mensagens da tarefa atual, incluindo etapas, avisos e erros. Ao iniciar outra tarefa, a interface cria um novo arquivo de log; os registros anteriores permanecem em `launcher/logs`.

### Abrir arquivo

Abre no Bloco de Notas o arquivo de log da tarefa mais recente. Se nenhuma tarefa foi iniciada nesta sessão, o botão não tem arquivo para abrir.

### Barra de progresso e estado

O texto de estado informa a etapa em andamento ou se ela terminou/falhou. A barra fica animada quando não há percentual real disponível. Ao concluir, o estado informa o resultado e o código de saída em caso de falha.

## Sequência recomendada

Para preparar um ambiente novo, selecione o cliente e use **Instalação completa**. Depois, confira a conclusão na aba **Logs**, use **Iniciar servidor** e siga [Configurar e jogar](03-configurar-e-jogar.md) para criar uma conta e entrar no reino. Para desligar, siga **ENCERRAR SERVIÇOS** e depois use **ENCERRAR MYSQL**.
