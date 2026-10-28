# 3. Configurar e jogar

## Aplicar o perfil

Com os binários compilados e MySQL configurado, rode:

```powershell
scripts\03-extrair-dados.ps1
scripts\04-configurar-servidor.ps1
scripts\11-importar-bancos.ps1
scripts\13-configurar-reino.ps1
scripts\05-instalar-addons.ps1 -ClientPath 'C:\caminho\do\cliente'
```

Para instalar apenas o AltBot após a configuração completa, sem substituir os outros addons:

```powershell
scripts\05-instalar-addons.ps1 -ClientPath 'C:\caminho\do\cliente' -Only AltBot
```

Se você interromper a extração depois que os MMAPs terminarem, sincronize os arquivos restantes sem remover os dados em uso com `scripts\12-finalizar-dados.ps1 -Stage <pasta-do-estagio>`.

`04-configurar-servidor.ps1` preserva cópias dos `.conf` anteriores antes de editar. Ela configura o reino em loopback, nível máximo 80 e as taxas definidas em `config/perfil-servidor.json` (inicialmente XP 7x, drop de itens 4x, dinheiro de loot 10x e dinheiro de quests 10x), além do perfil de bots.

O módulo `mod-wow-teleporter` é incluído na compilação. Após adicioná-lo a um servidor já preparado, execute novamente `scripts\02-compilar-servidor.ps1`, `scripts\04-configurar-servidor.ps1` e `scripts\11-importar-bancos.ps1`, depois reinicie o reino. Instale os addons com `scripts\05-instalar-addons.ps1 -ClientPath 'C:\caminho\do\cliente' -Only HeraldWotLK,SoloRealmAddons` e reinicie o cliente.

O NPC **Teleportador** aparece em Stormwind, perto do ponto de chegada. O addon **Solo Realm Addons** abre o menu em qualquer lugar com `/teleport` ou pelo botão **Teletransportes** no menu `Esc`; seu atalho configurável fica em **Esc → Teclas → Solo Realm Addons**. Escolha o continente e o destino; o servidor impede viagens durante combate, voo ou morte e aplica o nível mínimo indicado.

A **Loja do Reino** vende glifos, montarias terrestres e voadoras, montarias raras, mascotes, bolsas, consumíveis, materiais e armas lendárias por gold do personagem. No addon, use os filtros de classe e nível do personagem para restringir a lista; por padrão, ambos correspondem ao personagem atual. Os NPCs Mercador do Reino filtram automaticamente pelos requisitos de classe e nível do personagem. Os preços usam cobre e exibem ouro, prata e cobre; itens com preço de vendedor seguem o preço-base do jogo, e itens sem preço de vendedor têm estimativas. A loja abre com `/shop`, pelo botão **Loja de Ouro** no menu `Esc` ou pelo atalho em **Esc → Teclas → Solo Realm Addons**. Selecionar um produto apenas mostra seus detalhes e a prévia; a compra só ocorre pelo botão **Comprar**. Equipamentos são mostrados em um modelo de prévia isolado, e os demais itens aparecem pelo ícone, sem equipar o personagem. Os NPCs Mercador do Reino também estão nas oito capitais. O servidor confere saldo e espaço na bolsa antes de cobrar e entregar o item.

O addon **Solo Realm Addons** adiciona **Loja de Ouro**, **Teletransportes** e **Resetar Talentos**, nesta ordem, ao menu `Esc`. O reset também abre com `/resettalentos`, é gratuito e afeta a especialização ativa. O botão de reset pede confirmação.

Confirme que `servidor/run/Data` contém `dbc`, `maps`, `vmaps` e `mmaps`. Em `worldserver.conf`, a opção `DataDir` deve apontar para esse diretório.

## Reino e conta

1. `scripts/13-configurar-reino.ps1` aplica `sql/01-reino-local.sql` após a importação e confirma o endereço do realm no banco.
2. Inicie os servidores com `scripts/06-iniciar-servidor.ps1`.
3. No console do `worldserver`, crie uma conta normal com `.account create <usuario> <senha>`; não use `.account set gmlevel`.
4. Confirme `set realmlist 127.0.0.1` no `Data/<locale>/realmlist.wtf` do cliente. Guarde uma cópia do arquivo antes de alterar.
5. Faça login com o cliente 3.3.5a, selecione **Reino Local** e crie um personagem da Aliança.

O extrator trabalha numa cópia temporária e não altera os mapas nem o idioma do cliente. O arquivo de realmlist é alterado separadamente para a conexão local; restaure sua cópia para voltar a conectar a outro reino.

## Controle dos bots

- O addon **MultiBot Chatless** precisa de `mod-multibot-bridge` compilado e carregado. Copie o addon como `Interface/AddOns/MultiBot`.
- O painel **DungeonClear** instala em `Interface/AddOns/DungeonClear`.
- **AltBot** instala em `Interface/AddOns/AltBot`. No Quest Mode, bots seguem o personagem mestre; no Farm Mode, bots exploram e fazem grind sem acompanhamento. O personagem mestre não joga sozinho.
- Convide bots Playerbots para o grupo pelo MultiBot. Para dungeon clear, use um tank-bot e jogue como seguidor/DPS. Use o painel para On, Pause/Resume, Skip e Off.
- Os bots aleatórios podem aparecer, fazer quests, conversar e usar LFG por conta própria. A população e proporção de facções são alvos percentuais, não uma contagem garantida por facção em cada instante.

Referências: [MultiBot Chatless](https://github.com/Wishmaster117/MultiBot-Chatless), [Bridge](https://github.com/Wishmaster117/mod-multibot-bridge), [Dungeon Clear](https://github.com/jrad7/mod-dungeon-clear), [addon Dungeon Clear](https://github.com/jrad7/mod-dungeon-clear-addon).
