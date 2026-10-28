# 2. Baixar fontes e compilar

Abra PowerShell na pasta clonada do kit. Se a política de execução bloquear scripts locais, use uma sessão temporária com `Set-ExecutionPolicy -Scope Process Bypass`; isso não altera a política permanente do Windows.

## Ordem de execução

```powershell
scripts\00-verificar-pre-requisitos.ps1
scripts\01-baixar-fontes.ps1
scripts\02-compilar-servidor.ps1
```

O repositório publica os SHAs em `config/fontes.lock.json`. O script clona o fork Playerbot e os módulos nessa revisão, aplica `patches/playerbots-herald.patch` ao `mod-playerbots` e salva o lock usado em `servidor/fontes.lock.json`. O patch inclui os comandos e estados do Herald, usa o New RPG como piloto e mantém o servidor remoto de comandos desativado. Reexecuções usam as mesmas revisões; não avançam branches automaticamente.

Para executar o fluxo completo após instalar as dependências, use `scripts/instalar.ps1 -ClientPath 'C:\caminho\do\cliente'`. Ele compila, extrai os dados do cliente, configura MySQL e os bancos, aplica o perfil e instala os addons. A conta do jogo é criada manualmente no console depois; nenhuma senha de jogo é pedida nem salva pelo kit.

Para pedir uma atualização de fontes, faça primeiro backup e encerre os servidores. Depois execute `scripts/08-atualizar-fontes.ps1 -RefreshPins`. O script tira e reaplica o patch Herald somente quando o checkout contém exatamente o patch publicado; alterações locais adicionais bloqueiam a atualização.

## Compilação

Use `scripts\02-compilar-servidor.ps1` no terminal ou o botão **Compilar servidor** do launcher. O script escolhe o paralelismo com base na memória disponível; você pode defini-lo com `-ParallelJobs N`. Binários e configs ficam em `servidor/run`; o código-fonte fica em `servidor/src/azerothcore-wotlk`.

Se o CMake não localizar Boost, MySQL ou OpenSSL, corrija `BOOST_ROOT` e os caminhos de instalação; rode novamente a verificação e o build. Não substitua a fonte Playerbot pelo repositório AzerothCore padrão: o módulo depende de alterações presentes no fork.

## MySQL local e realm

O fluxo roda `scripts/10-configurar-mysql.ps1`, cria um diretório de dados em `servidor/mysql-data`, escuta em `127.0.0.1`, gera senhas aleatórias e prepara os quatro bancos. A senha administrativa fica protegida por DPAPI para sua conta; a senha de runtime fica nos arquivos privados ignorados pelo Git. `scripts/13-configurar-reino.ps1` define e confirma o realm `Reino Local` depois da importação dos bancos.

## Configuração de senha

`scripts/04-configurar-servidor.ps1` gera os `.conf` locais e preenche as conexões do banco. Depois `scripts/11-importar-bancos.ps1` usa o `dbimport` para aplicar tabelas-base e migrations do core e dos módulos.
