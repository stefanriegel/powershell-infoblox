$ErrorActionPreference = 'Stop'

# Generate timestamp for CSV filename
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$csvFile = Join-Path -Path $PSScriptRoot -ChildPath ("empty_subnets-$timestamp.csv")

try {
    Import-Module ibPS -ErrorAction Stop
    $apiKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '.b1apikey'
    if (-Not (Test-Path $apiKeyPath)) {
        Write-Error "API key file '.b1apikey' not found."
        exit 1
    }
    $ApiKey = (Get-Content $apiKeyPath -Raw).Trim()
    $profileName = 'universal-ddi-eu'
    if (-not (Get-B1ConnectionProfile -Name $profileName -ErrorAction SilentlyContinue)) {
        New-B1ConnectionProfile -Name $profileName -CSPRegion EU -APIKey $ApiKey | Out-Null
    }
    $currentProfile = (Get-B1ConnectionProfile | Where-Object { $_.Active -eq $true }).Name
    if ($currentProfile -ne $profileName) {
        Switch-B1ConnectionProfile -Name $profileName | Out-Null
    }
    $spaces = Get-B1Space
    $allSubnets = foreach ($space in $spaces) { Get-B1Subnet -space $space.id }
    $emptySubnets = $allSubnets | Where-Object {
        ([int]($_.utilization.used) -eq 2) -and (([int]($_.utilization_v6.used) -eq 0) -or ($_.utilization_v6.used -eq $null))
    }
    if ($emptySubnets.Count -gt 0) {
        $humanReadableSubnets = $emptySubnets | ForEach-Object {
            $firstSeen = $null; $lastSeen = $null
            if ($_.discovery_metadata.first_discovered_timestamp) {
                $firstSeen = try { [datetime]::Parse($_.discovery_metadata.first_discovered_timestamp).ToString('yyyy-MM-dd HH:mm:ss') } catch { $_.discovery_metadata.first_discovered_timestamp }
            }
            if ($_.discovery_metadata.last_discovered_timestamp) {
                $lastSeen = try { [datetime]::Parse($_.discovery_metadata.last_discovered_timestamp).ToString('yyyy-MM-dd HH:mm:ss') } catch { $_.discovery_metadata.last_discovered_timestamp }
            }
            [PSCustomObject]@{
                Name = $_.name
                Address = $_.address
                CIDR = $_.cidr
                Location = $_.location
                'Cloud Provider' = $_.discovery_metadata.discoverer
                'Subnet Creation Date' = $_.created_timestamp
                'First Seen' = $firstSeen
                'Last Seen' = $lastSeen
            }
        }
        $humanReadableSubnets | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
        Write-Host "Found $($emptySubnets.Count) empty subnets. Exported to $csvFile"
    } else {
        Write-Host "No empty subnets found."
    }
} catch {
    Write-Error $_
    exit 1
} 