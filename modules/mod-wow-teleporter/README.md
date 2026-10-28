# Teletransportador do reino

Módulo AzerothCore para WotLK 3.3.5a. O NPC 900100 abre um gossip com destinos
separados por região. O comando `.wowteleport <índice>` faz a viagem e é usado
pelo menu `/teleport` do addon Herald WotLK, que também pode ser associado a uma
tecla. O servidor exige o nível mínimo indicado e recusa teletransporte durante
combate, voo, morte ou outro teletransporte. O spawn fica em Stormwind.

O instalador copia este módulo para `servidor/src/azerothcore-wotlk/modules`
antes da compilação. O SQL do módulo é aplicado pelo `dbimport` na próxima
execução de `scripts/11-importar-bancos.ps1`.

O catálogo é definido em `src/shop_catalog.h`; o catálogo apresentado no
cliente fica em `addons/SoloRealmAddons/ShopCatalog.lua`. Os preços de itens com custo
de vendedor usam o preço-base da tabela de itens, em cobre; itens sem esse
preço usam estimativas explícitas. O catálogo inclui os glifos WotLK e a loja
dos NPCs pagina os produtos para respeitar o limite de opções do gossip.
As compras usam a moeda do personagem e entregam os itens diretamente na bolsa.

A loja abre pelo comando `/shop`, pela bind **Abrir loja do reino** ou nos NPCs
Mercador do Reino das oito capitais. O addon envia somente o índice do produto;
preço, saldo, espaço e entrega são conferidos pelo servidor. O comando interno
de compra é `.wowshop buy <índice>`.

## Reset gratuito de talentos

Digite `/resettalentos` no chat ou use **Resetar talentos** no menu Esc. O botão
pede confirmação. O addon envia o comando interno `.resettalentos` ao servidor.
O reset afeta apenas os talentos da especialização ativa do
personagem conectado, não cobra gold e atualiza a janela de talentos. Para
resetar a outra especialização, ative-a antes de usar o comando novamente.
O comando é recusado durante combate, voo, teletransporte ou morte.
