# Muestra el menu de opciones
function display_options {
    Write-Host " 
    ++++++ Menu ++++++
    [1] Automatic CSV
    [2] Manual User
    "

    read_menu_options
}

# Lee la opcion del menu
function read_menu_options {
    $chose_option = Read-Host "Choose option ~>"

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

# Lee el archivo CSV y lo devuelve como un array
function auto_csv {
    $csv_data                       = Import-Csv -Path test.csv -Delimiter ',' -Header @("name", "subname", "ou", "group") | Select-Object -Skip 1

    return $csv_data
}


# Genera un nombre de usuario basado en el nombre y apellido
function username_generator {
    param($proces_csv_data)

    $name_part                      = $proces_csv_data.name.Substring(0, [Math]::Min(4, $proces_csv_data.name.Length))
    $subname_part                   = $proces_csv_data.subname.Substring(0, [Math]::Min(4, $proces_csv_data.subname.Length))

    return $name_part + $subname_part
}

# Obtiene el dominio en formato DC=domain,DC=com
function domain_ad {
    return (Get-ADDomain).DistinguishedName
}

# Crea un usuario en Active Directory
function create_user {
    param([array]$csv_data)

    foreach ($proces_csv_data in $csv_data) {
        $user_name                  = username_generator -proces_csv_data $proces_csv_data
        $domain_name                = domain_ad

        # Construye el Distinguished Name (DN) de la OU
        $complete_domain            = "OU=$($proces_csv_data.ou),$domain_name"

        # Crea el usuario en AD
        New-ADUser -Name $user_name `
            -GivenName              $proces_csv_data.name `
            -Surname                $proces_csv_data.subname `
            -UserPrincipalName      $user_name@$(($domain_name -split ',')[0] -replace 'DC=','') `
            -Path                   $complete_domain `
            -AccountPassword        (ConvertTo-SecureString $user_name -AsPlainText -Force) `
            -Enabled                $true `
            -ChangePasswordAtLogon  $true
    }
}

# Muestra el formato para ingreso manual
function display_form {
    Write-Host " 
    ++++++ Manual Input Format ++++++
    Enter details separated by ','
    Format user_name,name,subname,ou
    "
}

# Captura la entrada manual y valida el formato
function menu_manual_option {
    display_form

    $chose_option                   = Read-Host "Enter details ~ "

    $values                         = $chose_option -split ','

    if ( $values.Count -eq 4 ) {
        return $values
    } else {
        Write-Host "Incorrect format! Try again."
        return menu_manual_option
    }
}

# Crea un usuario manualmente
function manual_user {
    $domain_name                        = domain_ad
    $user_manual_config                 = menu_manual_option

    $user_name                          = $user_manual_config[0]
    $given_name                         = $user_manual_config[1]
    $surname                            = $user_manual_config[2]
    $ou                                 = $user_manual_config[3]

    # Construye el Distinguished Name (DN) de la OU
    $complete_domain                    = "OU=$ou,$domain_name"

    # Crea el usuario en AD
    New-ADUser -Name $user_name `
        -GivenName                      $given_name `
        -Surname                        $surname `
        -UserPrincipalName              $user_name@$(($domain_name -split ',')[0] -replace 'DC=','') `
        -Path                           $complete_domain `
        -AccountPassword                (ConvertTo-SecureString $user_name -AsPlainText -Force) `
        -Enabled                        $true `
        -ChangePasswordAtLogon          $true
}

function add_group() {
    param([array]$csv_data)
    Add-ADGroupMember -Identity $csv_data.grup -Members $csv_data.user_name
}

# Inicia el script
display_options