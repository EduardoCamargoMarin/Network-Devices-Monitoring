# Monitoring Devices on your network and test network basic connections

# Log Directory
$logDiR = "C:\Scripts"


# It Creates a separated log each day
if(!(Test-Path -Path $logDiR)) {
    New-Item -ItemType Directory -Path $logDiR | Out-Null
}

$logFile = Join-Path -Path $logDir -ChildPath "MonitoramentoDeDispositivos_$(Get-Date -Format 'dd-MM-yyyy').log"


# Basic test connections
$targets = @("google.com", "8.8.8.8", "1.1.1.1", "200.160.0.8")

# DNS settings validation test
$dnsHost = @("uol.com", "ntp.br", "meuip.com", "youtube.com") #IPV6 and IPV4 websites


function Network-Data {
    $IPAddress = ipconfig
    $ValidIP = iwr ipinfo.io/ip

    foreach ($output in $IPAddress) {
        if($output -match "Adaptador|IPv4|IPv6|Máscara|Gateway Padrão") { # will match the following text for better view.
            Write-Host $output -ForegroundColor Yellow
    }
    }
    Write-Host "=============================="
    Write-Host ""
    Write-Host "IP Público:" -ForegroundColor Cyan
    Write-Host $ValidIP -ForegroundColor Yellow
}


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


function Route-Tracert {
    $target = "8.8.8.8"
    Write-Host "Executando rastreamento de rota para $target... Por favor aguardar o resultado" -ForegroundColor Cyan

    try {
        # Initialize Tracert and show the results by the end of the test.
        $traceResult = tracert $target | ForEach-Object { $_ } # Return the result for the "tracert" command.

        Write-Host "Resultados do rastreamento de rota para $target :" -ForegroundColor Yellow

        foreach ($line in $traceResult) {
            Write-Host $line -ForegroundColor Green
        }

        # Log saved
        Add-Content -Path $logFile -Value "Rastreamento de rota para $target em [$(Get-Date)]:"
        $traceResult | ForEach-Object {
            Add-Content -Path $logFile -Value $_
        }
    }
    catch {
        $errorMessage = "[ $target ] Erro ao executar rastreamento de rota: $($_.Exception.Message)"
        Write-Host $errorMessage -ForegroundColor Red
        Add-Content -Path $logFile -Value $errorMessage
    }
}


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


# Admin check function
function Admin-Verify {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        Write-Host "Este script requer permissões administrativas. Reiniciando com privilégios elevados..." -ForegroundColor Yellow

        # Admin PS path
        $scriptPath = $PSCommandPath

        # Relaunch PS
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

# Check if we are using Admin privilege
Admin-Verify


# option 5 selected, check if Chocolatey is installed before selecting the installation options.

function Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey não está instalado. Instalando agora..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey instalado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "Erro ao instalar o Chocolatey. Verifique sua conexão ou permissões." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Chocolatey já está instalado." -ForegroundColor Green
    }
    return $true
    Pause
}

# Avoid downloading twice
function Is-ProgramInstalled {
    param([string]$programName)
    $program = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$programName*" }
    return $program -ne $null
}

# Function to select which program to install

function Install-Programs-Menu {
    while($true) {
        Clear-Host
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host "           Softwares para TI             " -ForegroundColor Cyan
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " 1. Advanced IP Scanner"
        Write-Host ""
        Write-Host " 2. Crystal Disk Info"
        Write-Host ""
        Write-Host " 3. Nmap"
        Write-Host ""
        Write-Host " 4. WireShark"
        Write-Host ""
        Write-Host " 5. Rufus"
        Write-Host ""
        Write-Host " 6. Acesso remoto (Anydesk, TeamViewer)"
        Write-Host ""
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host "           Pacotes de instalação             " -ForegroundColor Cyan
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " 7. Básico (Chrome, Firefox, AdobeReader, VLC, Jr8, Zoom, Winrar)"
        Write-Host ""
        Write-Host " 8. Voltar"
        $opcao = Read-Host " Escolha uma opção (1-8)"

        switch($opcao) {
        
        "1" {
        $program = "advanced-ip-scanner"
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
            # if an error occurs, you must download the program by hand.
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
           }
           Pause
          }
        "2" {
        $program = "crystaldiskinfo"
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
            # if an error occurs, you must download the program by hand.
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
           }
           Pause             
          }
        "3" {
        $program = "nmap"
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
            # if an error occurs, you must download the program by hand.
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
           }
           Pause             
          }
        "4" {
        $program = "wireshark"
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
            # if an error occurs, you must download the program by hand.
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
           }
           Pause             
          }
        "5" {
        $program = "rufus"
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
            # if an error occurs, you must download the program by hand.
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
           } 
           Pause            
          }

        "6" { 
            $programs = @("anydesk", "teamviewer")
    
            foreach ($program in $programs) {
                if (Is-ProgramInstalled -programName $program) {
                    Write-Host "$program já está instalado." -ForegroundColor Yellow
             } else {
                 try {
                        Write-Host "Instalando $program..." -ForegroundColor Green
                     choco install $program -y
                     Write-Host "$program instalado com sucesso!" -ForegroundColor Green
                  } 
                 catch {
                    # if an error occurs, you must download the program by hand.
                     Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
 }

        "7" { 
            $programs = @("winrar", "googlechrome", "firefox", "vlc", "adobereader", "jre8", "zoom")
    
            foreach ($program in $programs) {
                if (Is-ProgramInstalled -programName $program) {
                    Write-Host "$program já está instalado." -ForegroundColor Yellow
             } else {
                 try {
                        Write-Host "Instalando $program..." -ForegroundColor Green
                     choco install $program -y
                     Write-Host "$program instalado com sucesso!" -ForegroundColor Green
                  } 
                 catch {
                    # if an error occurs, you must download the program by hand.
                     Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
 }
        "8" { return menu}              
  }
 }
}


# Full scan Defender
function Run-FullScan {
    Write-Host "Iniciando verificação completa do Windows Defender..." -ForegroundColor Green
    try {
        Start-MpScan -ScanType FullScan #initialize Windows Scan

        Write-Host "Verificação completa finalizada!" -ForegroundColor Green
    } 
    catch {
        Write-Host "Erro ao executar verificação completa do Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Quick scan Defender
function Run-QuickScan {
    Write-Host "Iniciando verificação rápida do Windows Defender..." -ForegroundColor Green
    try {
        Start-MpScan -ScanType QuickScan #initialize Windows Scan

        Write-Host "Verificação rápida finalizada!" -ForegroundColor Green
    } 
    catch {
        Write-Host "Erro ao executar verificação rápida do Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}



function Windows-Update {
    try {
        Write-Host "Verificando atualização do Windows..." -ForegroundColor Yellow

        # Checking if PSWindowsUpdate is installed
        if(!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "PSWindowsUpdate não encontrado. Instalando módulo..." -ForegroundColor Cyan
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
        }

        #import module
        Import-Module PSWindowsUpdate


        #Show available updates
        $update = Get-WindowsUpdate
        
        if($update) {
            Write-Host "As seguintes atualizações estão disponíveis:" -ForegroundColor Cyan
            $update | Format-Table -AutoSize


        # User's confirmation
        $confirm = Read-Host "Deseja instalar todas as atualizações? O COMPUTADOR PODE REINICIALIZAR, SALVAR TODOS OS ARQUIVOS ANTES DE PROSSEGUIR!! (S/N):  "
        if($confirm -eq "S") {
            Write-Host "Instalando atualizações. Isso pode levar alguns minutos."
             Install-WindowsUpdate -AcceptAll -ForceInstall -AutoReboot
            Write-Host "Atualizações instaladas com sucesso!" -ForegroundColor Green
        }
        else {
            Write-Host "Instalação não realizada." -ForegroundColor Red
        }
    }
}
catch {
        Write-Host "Erro ao verificar ou instalar atualizações: $($_.Exception.Message)" -ForegroundColor Red
    }
}




# Show Menu

function menu {
    while ($true) {
        Clear-Host
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host "       Menu de Verificação da rede     " -ForegroundColor Cyan
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " 0. Dados da rede local (LAN)"
        Write-Host ""
        Write-Host " 1. Validação de DNS"
        Write-Host ""
        Write-Host " 2. Configuração da rede para teste de dispositivos"
        Write-Host ""
        Write-Host " 3. Verificação dos status dos dispositivos na rede (Requer a configuração do item 2)"
        Write-Host ""
        Write-Host " 4. Teste de conectividade para internet"
        Write-Host ""
        Write-Host " 5. Rastreamento de rotas na rede"
        Write-Host ""
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host "       Menu do Computador local          " -ForegroundColor Cyan
        Write-Host " ========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " 6. Pacotes de instalação"
        Write-Host ""
        Write-Host " 7. Verificação Rápida do Windows Defender (recomendado)"
        Write-Host ""
        Write-Host " 8. Verificação Completa do Windows Defender (Processo demorado. Usar em último recurso)"
        Write-Host ""
        Write-Host " 9. Executar Windows Update"
        Write-Host ""
        Write-Host " 10. Sair"
        Write-Host ""
        $opcao = Read-Host " Escolha uma opção (1-10)"

        switch ($opcao) {

            "0" { Network-Data }

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
                Write-Host "Por favor, configure a rede selecionando o item 2 antes de iniciar o teste." -ForegroundColor Red
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
            "5" {Route-Tracert}
            
            "6" { 
                Chocolatey
                Install-Programs-Menu 
                }

            "7" { Run-QuickScan }

            "8" { Run-FullScan }

            "9" { Windows-Update }

            "10" { 
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