function Invoke-CIPPStandardSpoofWarn {
    <#
    .FUNCTIONALITY
    Internal
    #>
    param($Tenant, $Settings)

    # Input validation
    if ([string]::isNullOrEmpty($Settings.state) -or $Settings.state -eq 'Select a value') {
        Write-LogMessage -API 'Standards' -tenant $tenant -message 'SpoofWarn: Invalid state parameter set' -sev Error
        Return
    }

    $CurrentInfo = (New-ExoRequest -tenantid $Tenant -cmdlet 'Get-ExternalInOutlook')

    If ($Settings.remediate -eq $true) {
        $status = if ($Settings.enable -and $Settings.disable) {
            # Handle legacy settings when this was 2 separate standards
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'You cannot both enable and disable the Spoof Warnings setting' -sev Error
            Return
        } elseif ($Settings.state -eq 'enabled' -or $Settings.enable) { $true } else { $false }

        if ($CurrentInfo.Enabled -eq $status) {
            Write-LogMessage -API 'Standards' -tenant $tenant -message "Outlook external spoof warnings are already set to $status." -sev Info
        } else {
            try {
                New-ExoRequest -tenantid $Tenant -cmdlet 'Set-ExternalInOutlook' -cmdParams @{ Enabled = $status; }
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Outlook external spoof warnings set to $status." -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Could not set Outlook external spoof warnings to $status. Error: $ErrorMessage" -sev Error
            }
        }
    }

    if ($Settings.alert -eq $true) {
        if ($CurrentInfo.Enabled -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Outlook external spoof warnings are enabled.' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Outlook external spoof warnings are not enabled.' -sev Alert
        }
    }

    if ($Settings.report -eq $true) {
        Add-CIPPBPAField -FieldName 'SpoofingWarnings' -FieldValue $CurrentInfo.Enabled -StoreAs bool -Tenant $tenant
    }
}
