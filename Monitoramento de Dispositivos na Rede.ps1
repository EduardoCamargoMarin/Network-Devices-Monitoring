# Monitoring Devices on your network and test network basic connections

# Log Directory
$logDiR = "C:\Scripts"

if(!(Test-Path -Path $logDiR)) {
    New-Item -ItemType Directory -Path $logDiR | Out-Null
}

$logFile = Join-Path -Path $logDir -ChildPath "MonitoramentoDeDispositivos_$(Get-Date -Format 'dd-MM-yyyy').log"

# This parameters can change depending the network you are dealing with
$startIP = 1
$endIP = 254
$enderecamento = "192.168.10."

# Basic test connections
$targets = @("google.com", "8.8.8.8", "1.1.1.1", "ntp.br")

# DNS settings validation test
$dnsHost = @("google.com", "ntp.br", "meuip.com")

foreach ($dnsHosts in $dnsHost) {
    Write-Host "Testando verificação de DNS em $dnsHosts..." -ForegroundColor Yellow
    $dnsResult = Resolve-DnsName -Name $dnsHosts

    try {
        if($dnsResult) {
            $message = "DNS resolvido com sucesso para $dnsHosts"          
            Write-Host $message -ForegroundColor Green
        }
        else {
            $message = "Falha na resolução de DNS para $dnsHosts"
            Write-Host $message -ForegroundColor Red
        }

    }
    catch {
        # Error Details
        $errorMessage = "[ $dnsHosts ] Erro durante o teste: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMessage
        Write-Host $errorMessage -ForegroundColor Red
    }
}

Add-Content -Path $logFile -Value "Teste básico de conexão em [$(Get-Date)]"
Add-Content -Path $logFile -Value ""

foreach ($target in $targets) {
    Write-Host ""
    Write-Host "Testando conectividade com $target..." -ForegroundColor Yellow
    $result = Test-Connection -ComputerName $target -Count 2

    try{
    if($result) {
        Test-Connection -ComputerName $target -Count 2
        $message = "Conexão bem sucedida com $target"
        Write-Host $message -ForegroundColor Green
    }
    else {
        $message = "Falha ao conectar com $target"
        Write-Host $message -ForegroundColor Red
    }
   }
    catch {
        # Error Details
        $errorMessage = "[ $target ] Erro durante o teste: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMessage
        Write-Host $errorMessage -ForegroundColor Red
    }
    Add-Content -Path $logFile -Value ""
    Add-Content -Path $logFile -Value "[$(Get-Date)] $message"
    Add-Content -Path $logFile -Value ""
}

Add-Content -Path $logFile -Value "---------------------------------"
Add-Content -Path $logFile -Value "Monitoramento de dispositivos em [$(Get-Date)]"

function Testar-Dispositivo {
    param ( [string]$ip )

    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet
        if ($ping) {
            $message = "[ $ip ] está online"
            Add-Content -Path $logFile -Value ""
            Add-Content -Path $logFile -Value $message
            Write-Host $message -ForegroundColor Green
        } else {
            $message = "[ $ip ] não responde"
            Add-Content -Path $logFile -Value ""
            Add-Content -Path $logFile -Value $message
            Write-Host $message -ForegroundColor Red
        }
    } catch {
        # Error Details
        $errorMessage = "[ $ip ] Erro durante o teste: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMessage
        Write-Host $errorMessage -ForegroundColor Red
    }
}


for ($i = $startIP; $i -le $endIP; $i++) {

    $ip = $enderecamento + $i
    Testar-Dispositivo -ip $ip
}

Add-Content -Path $logFile -Value "Fim do teste em [$(Get-Date)]"
