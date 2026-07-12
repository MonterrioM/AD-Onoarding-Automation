# Import the Active Directory module
Import-Module ActiveDirectory

# Define paths
$CSVPath = "C:\Lab\NewEmployees.csv"
$LogFile = "C:\Lab\OnboardingLog.txt"

# Domain information
$Domain = "DC=mazetech,DC=local"

# Start log
"==================== $(Get-Date) ====================" | Out-File -FilePath $LogFile -Append

# Import CSV
$Users = Import-Csv -Path $CSVPath

foreach ($User in $Users) {

    try {

        # Build OU Distinguished Name based on Department
        $OU = "OU=$($User.Department),$Domain"

        # Build Display Name
        $DisplayName = "$($User.FirstName) $($User.LastName)"

        # Convert password to Secure String
        $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force

        # Create the AD User
        New-ADUser `
            -Name $DisplayName `
            -GivenName $User.FirstName `
            -Surname $User.LastName `
            -SamAccountName $User.Username `
            -UserPrincipalName "$($User.Username)@mazetech.local" `
            -DisplayName $DisplayName `
            -Path $OU `
            -AccountPassword $SecurePassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true

        # Determine security group
        $GroupName = "$($User.Department) Users"

        # Add user to department security group
        Add-ADGroupMember `
            -Identity $GroupName `
            -Members $User.Username

        # Log success
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') SUCCESS: Created user '$DisplayName' in '$OU' and added to group '$GroupName'." |
            Out-File -FilePath $LogFile -Append

    }
    catch {

        # Log failure
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ERROR: Failed to create user '$($User.Username)'. Error: $($_.Exception.Message)" |
            Out-File -FilePath $LogFile -Append

        # Display error on screen
        Write-Warning "Failed to process user $($User.Username): $($_.Exception.Message)"
    }
}

# Finish log
"==================== Script Completed $(Get-Date) ====================" | Out-File -FilePath $LogFile -Append

Write-Host "User onboarding completed. Review log at $LogFile" -ForegroundColor Green
