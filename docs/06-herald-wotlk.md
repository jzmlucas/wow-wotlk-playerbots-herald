# Herald Autopilot WotLK para este kit

## Situação

O Herald original do Open Vanilla não é somente um addon de interface: seu fluxo
depende do SelfBot do CMaNGOS, de comandos `.wnl autopilot` e `.rndbot cmd`, e de
alterações próprias no servidor. Esses arquivos não são compatíveis diretamente
com AzerothCore/cliente 3.3.5a. Este kit implementa uma adaptação nativa chamada
**Herald WotLK**, usando o motor New RPG/quest do `mod-playerbots` do próprio
servidor.

`Playerbots.SelfBotLevel = 2` permite SelfBot a contas normais no servidor local.
O modo Herald liga a estratégia New RPG, que escolhe quests WotLK, navega até
objetivos, combate, coleta e procura NPCs para aceitar/entregar quests. O foco é
questing de mundo aberto; isso não inclui todas as rotas, simulador nem sistema
de aprendizado do Herald original. O reino continua restrito ao PC (`127.0.0.1`)
e o servidor remoto de comandos do Playerbots permanece desativado (`CommandServerPort = 0`).

## Instalação e uso

Clone as fontes fixadas e aplique o patch do Herald antes de compilar. Para um
cliente já existente, instale o Herald e o addon unificado de loja, teletransporte e talentos com:

```powershell
scripts/05-instalar-addons.ps1 -ClientPath 'C:\caminho\do\cliente' -Only HeraldWotLK,SoloRealmAddons
```

No Windows, o script limita o compilador C++ a quatro workers e desativa somente
os símbolos de depuração dos módulos estáticos para reduzir memória e evitar
conflitos de geração de PDB do MSVC. Isso não remove código do servidor.

O addon Herald WotLK inclui um ícone de águia arrastável na minimapa. Clique nele para abrir
o painel ou use `/herald`. O addon Solo Realm Addons reúne a loja, o teletransporte e o reset de talentos,
com comandos `/shop`, `/teleport` e `/resettalentos` e teclas configuráveis em **Esc → Teclas** para loja e teletransporte. Reinicie servidor e cliente antes do primeiro uso.
Entre no mundo e o painel oferece
Iniciar questing, Pausar, Retomar, Parar e Ver estado. O comando equivalente é
`.playerbots bot herald start|pause|resume|stop|status`. **Parar desativa também o SelfBot e
devolve o controle manual.** Pausar interrompe o deslocamento, mas a IA pode
continuar reagindo em combate.

O modo é experimental. Começa pela localização atual e depende de dados de
quests, mapas, vmaps e mmaps válidos. Pode ficar sem progresso quando uma quest
não tem POI/objetivos navegáveis ou quando falta uma quest apropriada disponível.
Use Pausar ou Parar para retomar controle manual imediatamente.

## Limites em relação ao Herald original

O painel e os estados de controle foram adaptados ao cliente 3.3.5a. A execução
usa a navegação New RPG do `mod-playerbots`, que já contém rotinas WotLK para
objetivos, combate e interação com quest givers. Não foi portada a lógica
Vanilla específica de Northshire, o simulador, o aprendizado de rotas, nem o
controlador desktop/API do Open Vanilla. O controle do jogo permanece com você:
o Autopilot só roda enquanto você o inicia no painel e pode ser interrompido.

## Referências técnicas

- [Herald Autopilot original: dependências do realm e controle](https://github.com/orionopenwow/OpenVanilla/blob/main/autopilot/README.md)
- [Herald: estado e escopo anunciados](https://openvanilla.app/herald.html)
- [Playerbots AzerothCore: fork usado neste kit](https://github.com/mod-playerbots/azerothcore-wotlk)
