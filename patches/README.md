# Patch do Herald para Playerbots

`playerbots-herald.patch` adapta o SelfBot do Playerbots com os comandos e o
estado de execução do Herald WotLK e desativa o listener de comandos remotos.
O perfil habilita o New RPG. O patch foi gerado contra o commit
`e88cc4099e69f35126b28942a412ca702d20453b` do repositório
`mod-playerbots/mod-playerbots`, conforme `config/fontes.lock.json`.

`scripts/01-baixar-fontes.ps1` valida e aplica o patch uma vez. Em atualização
manual, remove esse patch somente se o checkout tiver exatamente as mudanças
publicadas, baixa os SHAs novos e tenta aplicá-lo novamente. Se o upstream mudar
de forma incompatível, o processo para e preserva a fonte para revisão.
