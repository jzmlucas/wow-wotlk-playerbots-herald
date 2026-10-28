using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using Microsoft.Win32;

namespace SoloRealm.Desktop;

public partial class MainWindow : Window
{
    private sealed record Setting(string Category, string Label, string Section, string Name, double Min, double Max, bool Integer = false, bool Boolean = false);
    private sealed record TaskSpec(string Label, string Script, bool NeedsClient = false, params string[] Arguments);

    private static readonly Setting[] Settings =
    [
        new("Progressão", "XP do jogador", "rates", "playerXp", .1, 100),
        new("Progressão", "XP efetiva dos bots", "rates", "botXpMultiplier", .1, 100),
        new("Progressão", "Drop de itens", "rates", "loot", .1, 100),
        new("Progressão", "Dinheiro de loot", "rates", "money", .1, 100),
        new("Progressão", "Dinheiro de quests", "rates", "questMoney", .1, 100),
        new("Progressão", "Reputação", "rates", "reputation", .1, 100),
        new("Progressão", "Honra", "rates", "honor", .1, 100),
        new("Criaturas e mundo", "Respawn mínimo (segundos)", "gameplay", "creatureRespawnMinimumSeconds", 1, 3600, true),
        new("Criaturas e mundo", "Taxa dinâmica de respawn", "gameplay", "creatureRespawnDynamicRate", .1, 10),
        new("Criaturas e mundo", "Vida de monstros normais", "gameplay", "creatureHealthMultiplier", .1, 100),
        new("Criaturas e mundo", "Dano de monstros normais", "gameplay", "creatureDamageMultiplier", .1, 100),
        new("Criaturas e mundo", "Distância de aggro", "gameplay", "creatureAggroMultiplier", .1, 10),
        new("Criaturas e mundo", "Perda de durabilidade (%)", "gameplay", "durabilityLossOnDeath", 0, 100, true),
        new("Criaturas e mundo", "Voos instantâneos", "gameplay", "instantFlightPaths", 0, 1, Boolean: true),
        new("Bots", "Mínimo de bots aleatórios", "bots", "minRandomBots", 0, 5000, true),
        new("Bots", "Máximo de bots aleatórios", "bots", "maxRandomBots", 0, 5000, true),
        new("Bots", "Nível mínimo", "bots", "minLevel", 1, 80, true),
        new("Bots", "Nível máximo", "bots", "maxLevel", 1, 80, true),
        new("Bots", "Máximo de bots convocados", "bots", "maxAddedBots", 0, 200, true),
        new("Bots", "Aliança (%) — Horda automática", "bots", "allianceRatio", 0, 100, true),
        new("Bots", "Chance de RPG (0 a 1)", "bots", "rpgChance", 0, 1),
        new("Bots", "Participar do LFG", "bots", "joinLfg", 0, 1, Boolean: true),
        new("Bots", "Bots conversam", "bots", "talk", 0, 1, Boolean: true),
        new("Bots", "Sugerir masmorras", "bots", "suggestDungeons", 0, 1, Boolean: true),
        new("Bots", "Convidar jogadores", "bots", "inviteHumanPlayers", 0, 1, Boolean: true),
        new("Bots", "Desativar sem jogador real", "bots", "disabledWithoutRealPlayer", 0, 1, Boolean: true),
        new("Bots", "Equipar melhorias de loot", "bots", "autoEquipUpgradeLoot", 0, 1, Boolean: true)
    ];

    private static readonly Dictionary<string, TaskSpec> Tasks = new()
    {
        ["start"] = new("Iniciar servidor", "scripts/06-iniciar-servidor.ps1"),
        ["backup"] = new("Criar backup", "scripts/07-backup.ps1"),
        ["install-all"] = new("Instalação completa", "scripts/instalar.ps1", true, "-ParallelJobs", "0"),
        ["check"] = new("Verificar pré-requisitos", "scripts/00-verificar-pre-requisitos.ps1"),
        ["sources"] = new("Baixar / atualizar fontes", "scripts/01-baixar-fontes.ps1"),
        ["compile"] = new("Compilar servidor", "scripts/02-compilar-servidor.ps1"),
        ["extract"] = new("Extrair mapas e dados", "scripts/03-extrair-dados.ps1", true),
        ["configure"] = new("Configurar servidor", "scripts/04-configurar-servidor.ps1"),
        ["mysql"] = new("Preparar MySQL", "scripts/10-configurar-mysql.ps1"),
        ["database"] = new("Atualizar bancos", "scripts/11-importar-bancos.ps1"),
        ["realm"] = new("Configurar reino local", "scripts/13-configurar-reino.ps1"),
        ["addons"] = new("Instalar addons", "scripts/05-instalar-addons.ps1", true),
        ["validate"] = new("Validar configuração", "scripts/09-validar-perfil.ps1"),
        ["stop-mysql"] = new("Encerrar MySQL", "scripts/07-encerrar-servidor.ps1")
    };

    private readonly Dictionary<Setting, Control> fields = new();
    private readonly List<Button> taskButtons = new();
    private readonly DispatcherTimer statusTimer = new() { Interval = TimeSpan.FromSeconds(4) };
    private readonly string root;
    private readonly string settingsFile;
    private readonly string logsDirectory;
    private bool busy;
    private string? currentLog;

    public MainWindow()
    {
        InitializeComponent();
        root = FindRoot();
        settingsFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "SoloRealm", "launcher.json");
        logsDirectory = Path.Combine(root, "launcher", "logs");
        Directory.CreateDirectory(logsDirectory);
        ClientPath.Text = ReadClientPath();
        BuildSettings();
        BuildInstallButtons();
        ShowPage("home");
        statusTimer.Tick += (_, _) => UpdateStatus();
        statusTimer.Start();
        UpdateStatus();
        AppendLog("SoloRealm pronto.");
        Closing += (_, e) => { if (busy) { e.Cancel = true; MessageBox.Show("Aguarde a tarefa atual terminar.", "Operação em andamento"); } else SaveClientPath(); };
    }

    private static string FindRoot()
    {
        foreach (var start in new[] { AppContext.BaseDirectory, Environment.CurrentDirectory })
        {
            for (var directory = new DirectoryInfo(start); directory is not null; directory = directory.Parent)
                if (File.Exists(Path.Combine(directory.FullName, "config", "perfil-servidor.json")) &&
                    File.Exists(Path.Combine(directory.FullName, "launcher", "Run-Task.ps1")))
                    return directory.FullName;
        }
        throw new DirectoryNotFoundException("SoloRealm.exe deve ficar dentro da pasta do kit, que contém config e launcher.");
    }

    private string ReadClientPath()
    {
        try { return JsonNode.Parse(File.ReadAllText(settingsFile))?["ClientPath"]?.GetValue<string>() ?? ""; }
        catch { return ""; }
    }

    private void SaveClientPath()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(settingsFile)!);
        File.WriteAllText(settingsFile, new JsonObject { ["ClientPath"] = ClientPath.Text.Trim() }.ToJsonString(), new UTF8Encoding(false));
    }

    private JsonObject ReadProfile() => JsonNode.Parse(File.ReadAllText(Path.Combine(root, "config", "perfil-servidor.json")))?.AsObject()
        ?? throw new InvalidDataException("Perfil do servidor inválido.");

    private void BuildSettings()
    {
        var profile = ReadProfile();
        fields.Clear();
        SettingsTabs.Items.Clear();
        foreach (var category in Settings.Select(s => s.Category).Distinct())
        {
            var stack = new StackPanel { Margin = new Thickness(18, 16, 18, 16) };
            foreach (var setting in Settings.Where(s => s.Category == category))
            {
                var row = new Grid { Margin = new Thickness(0, 0, 0, 10) };
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(310) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(155) });
                row.Children.Add(new TextBlock { Text = setting.Label, VerticalAlignment = VerticalAlignment.Center, Foreground = (Brush)FindResource("Text") });
                Control editor;
                if (setting.Boolean)
                    editor = new CheckBox { IsChecked = profile[setting.Section]?[setting.Name]?.GetValue<bool>() ?? false, VerticalAlignment = VerticalAlignment.Center };
                else
                    editor = new TextBox { Text = profile[setting.Section]?[setting.Name]?.ToString() ?? "", VerticalContentAlignment = VerticalAlignment.Center };
                Grid.SetColumn(editor, 1);
                row.Children.Add(editor);
                stack.Children.Add(row);
                fields[setting] = editor;
            }
            if (category == "Criaturas e mundo") stack.Children.Add(new TextBlock { Text = "Respawn altera o tempo de retorno. A criação de pontos de spawn exige alteração no banco de dados.", Foreground = (Brush)FindResource("Muted"), TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 12, 0, 0) });
            SettingsTabs.Items.Add(new TabItem { Header = category, Content = new ScrollViewer { Content = stack, VerticalScrollBarVisibility = ScrollBarVisibility.Auto } });
        }
        SettingsTabs.SelectedIndex = 0;
    }

    private void SaveProfile()
    {
        if (busy) throw new InvalidOperationException("Aguarde a tarefa atual terminar.");
        var profile = ReadProfile();
        var values = new Dictionary<string, double>();
        foreach (var setting in Settings)
        {
            var section = profile[setting.Section]?.AsObject() ?? throw new InvalidDataException($"Seção ausente: {setting.Section}");
            if (setting.Boolean) { section[setting.Name] = ((CheckBox)fields[setting]).IsChecked == true; continue; }
            var input = ((TextBox)fields[setting]).Text.Trim();
            if (!double.TryParse(input, NumberStyles.Float, CultureInfo.CurrentCulture, out var value) &&
                !double.TryParse(input, NumberStyles.Float, CultureInfo.InvariantCulture, out value))
                throw new InvalidDataException($"Valor inválido: {setting.Label}.");
            if (value < setting.Min || value > setting.Max || (setting.Integer && value != Math.Truncate(value)))
                throw new InvalidDataException($"{setting.Label}: use um valor entre {setting.Min} e {setting.Max}.");
            values[setting.Name] = value;
            section[setting.Name] = setting.Integer ? JsonValue.Create((int)value) : JsonValue.Create(value);
        }
        if (values["minRandomBots"] > values["maxRandomBots"] || values["minLevel"] > values["maxLevel"])
            throw new InvalidDataException("O valor mínimo dos bots não pode superar o máximo.");
        profile["bots"]!["hordeRatio"] = 100 - (int)values["allianceRatio"];
        var path = Path.Combine(root, "config", "perfil-servidor.json");
        var temp = path + ".tmp";
        File.WriteAllText(temp, profile.ToJsonString(new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
        File.Move(temp, path, true);
        AppendLog("Perfil salvo. Aplique a configuração e reinicie o worldserver.");
    }

    private void BuildInstallButtons()
    {
        foreach (var id in new[] { "install-all", "check", "sources", "compile", "extract", "configure", "mysql", "database", "realm", "addons", "validate", "stop-mysql" })
        {
            var button = new Button { Content = Tasks[id].Label.ToUpperInvariant(), Tag = id, Width = 220, Height = 56 };
            button.Click += RunAction;
            InstallActions.Children.Add(button);
            taskButtons.Add(button);
        }
    }

    private void ShowPage(string page)
    {
        HomePage.Visibility = page == "home" ? Visibility.Visible : Visibility.Collapsed;
        SettingsPage.Visibility = page == "settings" ? Visibility.Visible : Visibility.Collapsed;
        InstallPage.Visibility = page == "install" ? Visibility.Visible : Visibility.Collapsed;
        LogsPage.Visibility = page == "logs" ? Visibility.Visible : Visibility.Collapsed;
        PageTitle.Text = page switch { "settings" => "Configurações", "install" => "Instalação", "logs" => "Registros", _ => "Visão geral" };
    }

    private void Navigate(object sender, RoutedEventArgs e) => ShowPage((string)((Button)sender).Tag);

    private void BrowseClient(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFolderDialog { Title = "Selecione a pasta que contém Wow.exe e Data" };
        if (Directory.Exists(ClientPath.Text.Trim())) dialog.InitialDirectory = ClientPath.Text.Trim();
        if (dialog.ShowDialog(this) == true) { ClientPath.Text = dialog.FolderName; SaveClientPath(); }
    }

    private void SaveProfileClick(object sender, RoutedEventArgs e)
    {
        try { SaveProfile(); MessageBox.Show("Perfil salvo. Aplique a configuração e reinicie o worldserver.", "SoloRealm"); }
        catch (Exception ex) { MessageBox.Show(ex.Message, "Verifique os valores"); }
    }

    private async void ApplyProfileClick(object sender, RoutedEventArgs e)
    {
        try { SaveProfile(); await RunTaskAsync("configure"); }
        catch (Exception ex) { MessageBox.Show(ex.Message, "Falha ao aplicar"); }
    }

    private void ReloadProfileClick(object sender, RoutedEventArgs e)
    {
        if (MessageBox.Show("Descartar as alterações não salvas?", "Recarregar perfil", MessageBoxButton.YesNo) == MessageBoxResult.Yes) BuildSettings();
    }

    private async void RunAction(object sender, RoutedEventArgs e)
    {
        var id = (string)((Button)sender).Tag;
        try
        {
            if (id == "open-game")
            {
                var path = Path.Combine(ClientPath.Text.Trim(), "Wow.exe");
                if (!File.Exists(path)) throw new FileNotFoundException("Selecione uma pasta que contenha Wow.exe.");
                Process.Start(new ProcessStartInfo(path) { WorkingDirectory = Path.GetDirectoryName(path)!, UseShellExecute = true });
            }
            else if (id == "open-logs")
            {
                var path = Path.Combine(root, "servidor", "run", "startup-logs");
                Process.Start(new ProcessStartInfo(Directory.Exists(path) ? path : logsDirectory) { UseShellExecute = true });
            }
            else await RunTaskAsync(id);
        }
        catch (Exception ex) { AppendLog(ex.Message); MessageBox.Show(ex.Message, "SoloRealm"); }
    }

    private async Task RunTaskAsync(string id)
    {
        if (busy) throw new InvalidOperationException("Aguarde a operação atual terminar.");
        var task = Tasks[id];
        if (task.NeedsClient && (!File.Exists(Path.Combine(ClientPath.Text.Trim(), "Wow.exe")) || !Directory.Exists(Path.Combine(ClientPath.Text.Trim(), "Data"))))
            throw new DirectoryNotFoundException("Selecione a pasta do cliente WotLK com Wow.exe e Data.");
        if (id == "stop-mysql" && (PortOpen(3724) || PortOpen(8085)))
            throw new InvalidOperationException("Encerre o worldserver e o authserver nos consoles antes de parar o MySQL.");
        SaveClientPath();
        var arguments = new List<string>();
        if (task.NeedsClient) { arguments.Add("-ClientPath"); arguments.Add(ClientPath.Text.Trim()); }
        arguments.AddRange(task.Arguments);
        var jobFile = Path.Combine(Path.GetTempPath(), "solorealm-" + Guid.NewGuid().ToString("N") + ".json");
        var job = new { Script = Path.Combine(root, task.Script.Replace('/', Path.DirectorySeparatorChar)), Arguments = arguments, WorkingDirectory = root };
        File.WriteAllText(jobFile, JsonSerializer.Serialize(job), new UTF8Encoding(false));
        currentLog = Path.Combine(logsDirectory, DateTime.Now.ToString("yyyyMMdd-HHmmss") + "-" + id + ".log");
        File.WriteAllText(currentLog, "SoloRealm - " + task.Label + Environment.NewLine, new UTF8Encoding(false));
        var start = new ProcessStartInfo(Path.Combine(Environment.SystemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe"))
        {
            WorkingDirectory = root, UseShellExecute = false, CreateNoWindow = true,
            RedirectStandardOutput = true, RedirectStandardError = true
        };
        foreach (var item in new[] { "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", Path.Combine(root, "launcher", "Run-Task.ps1"), "-JobFile", jobFile }) start.ArgumentList.Add(item);
        using var process = new Process { StartInfo = start };
        busy = true;
        foreach (var button in taskButtons) button.IsEnabled = false;
        TaskStatus.Text = task.Label + " em andamento…";
        FooterStatus.Text = task.Label + " em andamento";
        ShowPage("logs");
        AppendLog("Iniciado: " + task.Label);
        try
        {
            process.Start();
            var stdout = PumpAsync(process.StandardOutput);
            var stderr = PumpAsync(process.StandardError);
            await Task.WhenAll(stdout, stderr, process.WaitForExitAsync());
            if (process.ExitCode != 0) throw new InvalidOperationException($"{task.Label} falhou (código {process.ExitCode}). Consulte {currentLog}.");
            TaskStatus.Text = task.Label + " concluído.";
            FooterStatus.Text = "Pronto";
            AppendLog("Concluído: " + task.Label);
            UpdateStatus();
        }
        finally
        {
            busy = false;
            foreach (var button in taskButtons) button.IsEnabled = true;
            try { File.Delete(jobFile); } catch { }
        }
    }

    private async Task PumpAsync(StreamReader reader)
    {
        while (await reader.ReadLineAsync() is { } line)
            await Dispatcher.InvokeAsync(() => AppendLog(line));
    }

    private void AppendLog(string message)
    {
        var line = $"{DateTime.Now:HH:mm:ss} {message}{Environment.NewLine}";
        LogOutput.AppendText(line);
        LogOutput.ScrollToEnd();
        if (currentLog is not null) File.AppendAllText(currentLog, line, new UTF8Encoding(false));
    }

    private void OpenTaskLog(object sender, RoutedEventArgs e)
    {
        if (currentLog is not null && File.Exists(currentLog)) Process.Start(new ProcessStartInfo("notepad.exe") { ArgumentList = { currentLog } });
    }

    private static bool PortOpen(int port)
    {
        try
        {
            using var client = new TcpClient();
            var attempt = client.ConnectAsync("127.0.0.1", port);
            return attempt.Wait(200) && client.Connected;
        }
        catch { return false; }
    }

    private void UpdateStatus()
    {
        var mysql = PortOpen(3306);
        var auth = PortOpen(3724);
        var world = PortOpen(8085);
        SetStatus(MysqlStatus, mysql);
        SetStatus(AuthStatus, auth);
        SetStatus(WorldStatus, world);
        RealmStatus.Text = world ? "REINO PRONTO" : auth || mysql ? "INICIALIZANDO" : "SERVIÇOS PARADOS";
    }

    private static void SetStatus(TextBlock block, bool online)
    {
        block.Text = online ? "ONLINE" : "OFFLINE";
        block.Foreground = new SolidColorBrush(online ? Color.FromRgb(126, 214, 167) : Color.FromRgb(238, 137, 119));
    }
}
