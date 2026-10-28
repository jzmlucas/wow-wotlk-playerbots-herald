# 4. Operação, backup e atualização

## Iniciar e encerrar

Rode `scripts/06-iniciar-servidor.ps1`. Ele inicia MySQL local em background e abre consoles visíveis para authserver e worldserver. Cada tentativa cria `servidor/run/startup-logs/<data-hora>/` com `launcher.log` e saídas `stdout`/`stderr` separadas por serviço. Os logs nativos do AzerothCore continuam em `servidor/run` (`Server.log`, `Auth.log` e `Errors.log`). Se um console fechar, consulte o `launcher.log` e os arquivos `*.stderr.log` da tentativa mais recente. Para desligar, use o console do worldserver e o comando `server shutdown 1`; aguarde o fechamento, depois feche o authserver. `scripts/07-encerrar-servidor.ps1` encerra MySQL com shutdown seguro quando os dois servidores já pararam.

## Backups

Antes de qualquer atualização, execute:

```powershell
scripts\07-backup.ps1
```

O script exige serviços parados e cria dumps dos bancos `acore_auth`, `acore_characters`, `acore_world` e `acore_playerbots`, além de cópia dos `.conf` e do lock de fontes. Ele usa o arquivo privado local de conexão do MySQL; os arquivos de configuração e credenciais em `servidor/` são ignorados pelo Git. O destino é `servidor/backups/<data-hora>`.

Mantenha cópias adicionais fora do computador se quiser proteção contra falha do disco. As cópias locais incluem configurações com credenciais e devem ser tratadas como privadas.

## Atualizações manuais

1. Faça backup e encerre authserver/worldserver.
2. Rode `scripts/08-atualizar-fontes.ps1 -RefreshPins` e confira a lista de mudanças.
3. Rode `scripts/02-compilar-servidor.ps1` novamente.
4. Reaplique configurações se os templates upstream mudaram e examine os logs das migrations.
5. Inicie e valide o servidor antes de continuar jogando.

O script não atualiza a instalação ao iniciar o servidor. A versão anterior dos SHAs fica no backup e no histórico de lock para comparação.
