# Display the menu options
function display_options {
    Write-Host "
    ++++++ Menu ++++++
    [1] Automatic CSV
    [2] Manual User
    "

    # Reference to read menu
    read_menu_options
}

# Read option form menu
function read_menu_options {
    $chose_option               = Read-Host "Chose option ~> "
    Write-Host $chose_option
    
    # Case options
    switch ($chose_option) {

        1 {
            create_user -csv_data (auto_csv)
        }

        2 {
            manual_user
        }

        default {
            Write-Host "Incorrect choice!"
            display_options
        }
    }
}

function auto_csv {
    # Reads the contents of the csv and adds them to an array
    $csv_data                   = Import-Csv -Path .\test.csv -Delimiter ',' -Header @("name", "subname", "ou") | Select-Object -Skip 1

    return $csv_data
}

# Create a random passowrd with numbers
function auto_password_generator {
    $random_pasword             = Get-Random

    return $random_pasword
}

# Generates names with first and last name
function username_generator {
    # Length of the name and subname
    $number_of_letters_name     = $proces_csv_data.id.Length
    $number_of_letters_subname  = $proces_csv_data.subname.Length

    # User name
    $user_name                  = $proces_csv_data.id.Substring(0, $number_of_letters_name) + $proces_csv_data.name.Substring(0, $number_of_letters_subname)

    return $user_name
}

function domain_ad {
    # Get domain AD in format "DC=domain_name,DC=com"
    $domainDN                   = (Get-ADDomain).DistinguishedName

    return $domainDN
}

# User crate function
function create_user {
    param( $csv_data )

    # Take arrays one by one
    foreach ($proces_csv_data in $csv_data) {

        # Function calls
        $random_pasword         = auto_password_generator
        $user_name              = username_generator
        $domain_name            = domain_ad

        # Domain + Organizational Unit variable
        $complete_domain        = "OU=$proces_csv_data.ou" + $domain_name

        # Create user in AD
        New-ADUser -Name $user_name `
            -GivenName             $proces_csv_data.name `
            -Surname               $proces_csv_data.subname `
            -UserPrincipalName     "$user_name@$domain_name" `
            -Path                  $complete_domain `
            -AccountPassword       (ConvertTo-SecureString $random_pasword -AsPlainText -Force) `
            -Enabled               $true `
            -ChangePasswordAtLogon $true
    }
}


display_options
