# Examples for a list of devices that you can added more later on
$devices = @(

    "192.168.10.1",  # Gateway

    "192.168.10.172" # Endpoint PC

    "8.8.8.8",       # Google DNS

    "1.1.1.1",       # Cloudflare DNS

    "google.com"     # Domain Test
)


# Live Monitoring
while ($true) {
    Clear-Host
    Write-Host "Monitoramento de dispositivos em tempo real - $(Get-Date)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------"

    foreach ($device in $devices) {
        $status = Test-Connection -ComputerName $device -Count 1 -Quiet

        try {
        if ($status) {
            Write-Host "[ONLINE] $device está respondendo" -ForegroundColor Green
            $pingResult = Test-Connection -ComputerName $device -Count 1
            Write-Host "Latência de $($pingResult.ResponseTime) ms" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "[OFFLINE] $device não está respondendo" -ForegroundColor Red
        }
       }
       catch {
       # Error Details
        $errorMessage = "[ $status ] Erro durante o teste: $($_.Exception.Message)"
        Write-Host $errorMessage -ForegroundColor Red
       }

    }

    Write-Host "`nPressione Ctrl+C para sair do monitoramento." -ForegroundColor Yellow
    Start-Sleep -Seconds 5  # Pausa de 5 segundos antes de atualizar
}
