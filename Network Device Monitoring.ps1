# Monitoring Devices on your network and test network basic connections

# Log Directory
$logDiR = "C:\Scripts"


# It Creates a separated log each day
if(!(Test-Path -Path $logDiR)) {
    New-Item -ItemType Directory -Path $logDiR | Out-Null
}

$logFile = Join-Path -Path $logDir -ChildPath "MonitoramentoDeDispositivos_$(Get-Date -Format 'dd-MM-yyyy').log"


# Basic test connections
$targets = @("google.com", "8.8.8.8", "1.1.1.1", "ntp.br")

# DNS settings validation test
$dnsHost = @("uol.com", "ntp.br", "meuip.com")


# DNS Validation
function DNS-Validation {
foreach ($dnsHosts in $dnsHost) {
    Write-Host "Testando verificação de DNS em $dnsHosts..." -ForegroundColor Yellow
    $dnsResult = Resolve-DnsName -Name $dnsHosts

    try {
        if($dnsResult) {
            $message = "DNS resolvido com sucesso para $dnsHosts"          
            Write-Host $message -ForegroundColor Green
            Write-Host ""
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

    Add-Content -Path $logFile -Value "[$(Get-Date)] $message"
}
}

Add-Content -Path $logFile -Value "Teste básico de conexão em [$(Get-Date)]"
Add-Content -Path $logFile -Value ""


# Connectivity Test
function Connectivity-Test {
foreach ($target in $targets) {
    Write-Host ""
    Write-Host "Testando conectividade com $target..." -ForegroundColor Yellow
    $result = Test-Connection -ComputerName $target -Count 2

    try{
    if($result) {
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
}

Add-Content -Path $logFile -Value "---------------------------------"
Add-Content -Path $logFile -Value "Monitoramento de dispositivos em [$(Get-Date)]"


# ICMP protocol on Endpoints

#Function to ICMP protocol

function Devices-Testing {
 param ( [string]$ip )

    try {
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet
        if ($ping) {
            $message = "[ $ip ] está online"
            Add-Content -Path $logFile -Value $message
            Write-Host $message -ForegroundColor Green
        } else {
            $message = "[ $ip ] não responde"
            Add-Content -Path $logFile -Value $message
            Write-Host $message -ForegroundColor Red
        }
    } catch {
        $errorMessage = "[ $ip ] Erro durante o teste: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value $errorMessage
        Write-Host $errorMessage -ForegroundColor Red
    }
}


#Network settings
function IP-Configuration {

    Write-Host "Configuração de teste de conectividade de rede" -ForegroundColor Cyan

    $enderecamento = Read-Host "Digite o endereço base da rede (exemplo: 192.168.10.)"
        $startIP = [int](Read-Host "Digite o IP inicial (exemplo: 1)")
            $endIP = [int](Read-Host "Digite o IP final (exemplo: 254)")
    return @($enderecamento, $startIP, $endIP)
}




# Show Menu

function menu {
    while ($true) {
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "          Menu de Monitoramento         " -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Validação de DNS"
        Write-Host ""
        Write-Host "2. Configuração da rede para teste de dispositivos"
        Write-Host ""
        Write-Host "3. Verificação de status dos dispositivos na rede (SELECIONE A OPÇÃO 2 ANTES DE PROSSEGUIR)"
        Write-Host ""
        Write-Host "4. Teste de conectividade para internet"
        Write-Host ""
        Write-Host "5. Sair"
        Write-Host ""
        $opcao = Read-Host "Escolha uma opção"

        switch ($opcao) {

            "1" { 
                DNS-Validation 
                Write-Host "Teste concluído. Resultados salvos em $logFile" -ForegroundColor Green
                }

            "2" { 
                 $configuracao = IP-Configuration
                    $enderecamento = $configuracao[0]
                        $startIP = $configuracao[1]
                             $endIP = $configuracao[2]
                    Write-Host "Configuração salva: Rede: $enderecamento, Início: $startIP, Fim: $endIP" -ForegroundColor Green
                 Pause
             }

            "3" { 
                if (-not $enderecamento -or -not $startIP -or -not $endIP) {
                Write-Host "Por favor, configure a rede antes de iniciar o teste." -ForegroundColor Red
            } else {
                Write-Host "Iniciando o teste de conectividade para os IPs na faixa: $enderecamento$startIP a $enderecamento$endIP" -ForegroundColor Yellow
                for ($i = $startIP; $i -le $endIP; $i++) {
                    $ip = "$enderecamento$i"
                    Devices-Testing -ip $ip
                }
                Write-Host "Teste concluído. Resultados salvos em $logFile" -ForegroundColor Green
            }
            Pause 
            }
            "4" { 
                Connectivity-Test 
                Write-Host "Teste concluído. Resultados salvos em $logFile" -ForegroundColor Green
                }

            "5" { 
            Write-Host "Saindo..." -ForegroundColor Yellow 
            Exit 
            }
            default { Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red }
        }

        Write-Host "`nPressione qualquer tecla para voltar ao menu..." -ForegroundColor Cyan
        Read-Host
    }
}

menu

Add-Content -Path $logFile -Value "Fim do teste em [$(Get-Date)]"