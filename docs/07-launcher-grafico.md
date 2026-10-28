# Launcher gráfico SoloRealm

O launcher oferece uma interface para executar os scripts do kit sem manter uma janela do PowerShell aberta. Ele mostra o estado das portas, permite escolher o cliente, acompanha a saída de cada tarefa e grava um log por operação em `launcher/logs`.

## Abrir

1. Baixe ou clone o repositório completo no Windows.
2. Dê dois cliques em `Abrir-SoloRealm.vbs` na raiz do repositório. Ele usa a build gráfica disponível ou compila o launcher atual com o SDK .NET 9.
3. Na primeira execução, escolha a pasta do cliente WotLK que contém `Wow.exe` e `Data`.
4. Use **Instalação completa** para preparar um ambiente novo ou selecione uma etapa na aba **Instalação e manutenção**.

O `Abrir-SoloRealm.vbs` inicia o executável gráfico atual quando ele já foi compilado. Em um clone limpo, ele compila e inicia `launcher/SoloRealm.Desktop` com o SDK .NET 9 na primeira abertura; os arquivos gerados ficam em pastas ignoradas pelo Git. O terminal fica oculto e os scripts existentes continuam sendo executados em segundo plano. Se a compilação ou a interface falhar, uma mensagem apresenta o erro e o detalhe fica em `launcher/logs/launcher-startup.log` e nos logs `desktop-launch.*.log`. O caminho do cliente fica salvo em `%LOCALAPPDATA%\SoloRealm\launcher.json`.

## Operações disponíveis

- Instalação completa, com download de fontes, compilação, configuração do banco, extração de dados e instalação dos addons.
- Verificação de dependências, atualização de fontes, compilação e extração de mapas em etapas separadas.
- Configuração do servidor, MySQL, bancos do reino, addons e validação do perfil.
- Inicialização do reino, abertura do cliente, backup e abertura da pasta de logs.
- Encerramento seguro do MySQL depois que o worldserver e o authserver forem encerrados.

Tarefas longas rodam em segundo plano. A barra fica animada quando os scripts não fornecem porcentagem real e mostra percentuais ou contagens somente quando a saída do processo as disponibiliza. Feche a janela apenas depois que a operação terminar.

## Logs e uso pelo terminal

Cada operação gera um arquivo com data e hora em `launcher/logs`. Os arquivos também aparecem na aba **Logs** e podem ser abertos no Bloco de Notas. Os scripts continuam disponíveis para quem preferir operar pelo terminal; veja [configurar e jogar](03-configurar-e-jogar.md).

O launcher não força o término do worldserver. Para parar o reino, use `server shutdown 1` no console do worldserver, feche o authserver e depois encerre o MySQL pela interface.

Para a descrição de cada botão e a sequência recomendada de uso, consulte o [Guia dos botões do launcher](08-guia-dos-botoes-do-launcher.md).
