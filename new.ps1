Add-Type -AssemblyName PresentationFramework

# Define functions for reading and writing JSON file
function Read-Switches {
    if (Test-Path -Path switches.json) {
        Get-Content -Path switches.json | ConvertFrom-Json
    } else {
        @()
    }
}

function Write-Switches {
    ([object[]]$switches)
    $switches | ConvertTo-Json | Set-Content -Path switches.json
}

# Create WPF window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Switch Manager" Width="700" Height="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <TextBox Grid.Row="0" Margin="5" Name="FilterBox" />
        <ListView Grid.Row="1" Margin="5" Name="SwitchList">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" />
                    <GridViewColumn Header="Description" DisplayMemberBinding="{Binding Description}" />
                    <GridViewColumn Header="IP Address" DisplayMemberBinding="{Binding IPAddress}" />
                    <GridViewColumn Header="Location" DisplayMemberBinding="{Binding Location}" />
                    <GridViewColumn Header="Tags" DisplayMemberBinding="{Binding Tags}" />
                </GridView>
            </ListView.View>
        </ListView>
        <StackPanel Grid.Row="2" Margin="5" Orientation="Horizontal">
            <Button Margin="0,0,5,0" Name="AddButton">Add</Button>
            <Button Margin="0,0,5,0" Name="EditButton">Edit</Button>
            <Button Margin="0,0,5,0" Name="DeleteButton">Delete</Button>
            <Button Margin="0,0,5,0" HorizontalAlignment="Right" Name="ConnectButton">Connect</Button>
        </StackPanel>
    </Grid>
</Window>
"@


$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$window=[Windows.Markup.XamlReader]::Load( $reader )

# Get references to controls
$SwitchList=$window.FindName('SwitchList')
$FilterBox=$window.FindName('FilterBox')
$AddButton=$window.FindName('AddButton')
$EditButton=$window.FindName('EditButton')
$DeleteButton=$window.FindName('DeleteButton')
$ConnectButton=$window.FindName('ConnectButton')

# Connect to switch function
function connectSwitch($switch) {
    # Add code here to connect to switch using information in $switch object
}

# Add sorting functionality to ListView
$lastHeaderClicked = $null
$lastDirection = "Ascending"

$SwitchList.AddHandler([System.Windows.Controls.GridViewColumnHeader]::ClickEvent, {
    param($sender, $e)

    $headerClicked = $e.OriginalSource
    if ($headerClicked -is [System.Windows.Controls.GridViewColumnHeader]) {
        if ($headerClicked.Role -ne [System.Windows.Controls.GridViewColumnHeaderRole]::Padding) {
            $direction = "Ascending"
            if ($headerClicked -eq $lastHeaderClicked) {
                if ($lastDirection -eq "Ascending") {
                    $direction = "Descending"
                }
            }

            $binding = $headerClicked.Column.DisplayMemberBinding.Path.Path
            $SwitchList.Items.SortDescriptions.Clear()
            $SwitchList.Items.SortDescriptions.Add((New-Object System.ComponentModel.SortDescription($binding, $direction)))
            $SwitchList.Items.Refresh()

            $lastHeaderClicked = $headerClicked
            $lastDirection = $direction
        }
    }
})

# Add filtering functionality to ListView
$FilterBox.Add_TextChanged({
    [string]$filterText=$FilterBox.Text

    if ([string]::IsNullOrWhiteSpace($filterText)) {
        [System.Collections.IEnumerable]$SwitchList.ItemsSource=Read-Switches
    } else {
        [array]$filteredSwitches=Read-Switches | Where-Object {
            $_.Name -match [regex]::Escape($filterText) -or
            $_.Description -match [regex]::Escape($filterText) -or
            $_.IPAddress -match [regex]::Escape($filterText) -or
            $_.Location -match [regex]::Escape($filterText) -or
            $_.Tags -match [regex]::Escape($filterText)
        }

        [System.Collections.IEnumerable]$SwitchList.ItemsSource=$filteredSwitches
    }
})

# Add event handlers for Add and Edit buttons
$AddButton.Add_Click({
    # Create form to add new switch
    $form = New-Object System.Windows.Window
    $form.Title = "Add Switch"
    $form.SizeToContent = "WidthAndHeight"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "5"
    $form.Content = $grid

    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

    $nameLabel = New-Object System.Windows.Controls.Label
    [string]$nameLabel.Content="Name:"
    [void]$grid.Children.Add($nameLabel)
    [System.Windows.Controls.Grid]::SetRow($nameLabel, 0)

    $nameBox = New-Object System.Windows.Controls.TextBox
    [System.Windows.Thickness]$nameBox.Margin="0,0,0,5"
    [void]$grid.Children.Add($nameBox)
    [System.Windows.Controls.Grid]::SetRow($nameBox, 1)

    $descriptionLabel = New-Object System.Windows.Controls.Label
    [string]$descriptionLabel.Content="Description:"
    [void]$grid.Children.Add($descriptionLabel)
    [System.Windows.Controls.Grid]::SetRow($descriptionLabel, 2)

    $descriptionBox = New-Object System.Windows.Controls.TextBox
    [System.Windows.Thickness]$descriptionBox.Margin="0,0,0,5"
    [void]$grid.Children.Add($descriptionBox)
    [System.Windows.Controls.Grid]::SetRow($descriptionBox, 3)

    # Add more controls for other properties as needed

    # Add Save and Cancel buttons to form
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    [System.Windows.Controls.Orientation]$buttonPanel.Orientation="Horizontal"
    [System.Windows.HorizontalAlignment]$buttonPanel.HorizontalAlignment="Right"
    [void]$grid.Children.Add($buttonPanel)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 7)

    $saveButton = New-Object System.Windows.Controls.Button
    [string]$saveButton.Content="Save"
    [System.Windows.Thickness]$saveButton.Margin="0,0,5,0"
    [bool]$saveButton.IsDefault=$true
    [void]$buttonPanel.Children.Add($saveButton)

    $cancelButton = New-Object System.Windows.Controls.Button
    [string]$cancelButton.Content="Cancel"
    [bool]$cancelButton.IsCancel=$true
    [void]$buttonPanel.Children.Add($cancelButton)

    # Add event handlers for Save and Cancel buttons
    $saveButton.Add_Click({
        # Create new switch object with entered data
        $newSwitch = @{
            UniqueID = [guid]::NewGuid()
            Name = $nameBox.Text
            Description = $descriptionBox.Text
            IPAddress = ""
            Location = ""
            Tags = ""
        }

        #Read the list of switches from the file and Add new switch to list of switches
        $switches = Read-Switches
        $switches += $newSwitch
        # Save changes to JSON file
        Write-Switches -switches $switches
        $switches = Read-Switches
        # Update ListView with new list of switches
        if ([string]::IsNullOrWhiteSpace($FilterBox.Text)) {
            # No filter applied, show all switches
            [System.Collections.IEnumerable]$SwitchList.ItemsSource=$switches
        } else {
            # Filter applied, show only matching switches
            [string]$filterText=$FilterBox.Text

            # Filter switches based on entered text in FilterBox
            [array]$filteredSwitches=$switches | Where-Object {
                $_.Name -match [regex]::Escape($filterText) -or
                $_.Description -match [regex]::Escape($filterText) -or
                $_.IPAddress -match [regex]::Escape($filterText) -or
                $_.Location -match [regex]::Escape($filterText) -or
                $_.Tags -match [regex]::Escape($filterText)
            }

            # Update ListView with filtered list of switches
            [System.Collections.IEnumerable]$SwitchList.ItemsSource=$filteredSwitches
        }

        # Save changes to JSON file
        Write-Switches -switches $switches
        
        # Close form
        $form.Close()
     })

     # Show form as dialog and wait for user input
     $form.ShowDialog()
})

$EditButton.Add_Click({
    # Get selected switch from ListView
    $selectedSwitch = $SwitchList.SelectedItem

    if ($selectedSwitch -ne $null) {
        # Create form to edit selected switch
        $form = New-Object System.Windows.Window
        $form.Title = "Edit Switch"
        $form.SizeToContent = "WidthAndHeight"

        $grid = New-Object System.Windows.Controls.Grid
        $grid.Margin = "5"
        $form.Content = $grid

        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
        $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

        $nameLabel = New-Object System.Windows.Controls.Label
        [string]$nameLabel.Content="Name:"
        [void]$grid.Children.Add($nameLabel)
        [System.Windows.Controls.Grid]::SetRow($nameLabel, 0)

        $nameBox = New-Object System.Windows.Controls.TextBox
        [System.Windows.Thickness]$nameBox.Margin="0,0,0,5"
        [string]$nameBox.Text=$selectedSwitch.Name
        [void]$grid.Children.Add($nameBox)
        [System.Windows.Controls.Grid]::SetRow($nameBox, 1)

        $descriptionLabel = New-Object System.Windows.Controls.Label
        [string]$descriptionLabel.Content="Description:"
        [void]$grid.Children.Add($descriptionLabel)
        [System.Windows.Controls.Grid]::SetRow($descriptionLabel, 2)

        $descriptionBox = New-Object System.Windows.Controls.TextBox
        [System.Windows.Thickness]$descriptionBox.Margin="0,0,0,5"
        [string]$descriptionBox.Text=$selectedSwitch.Description
        [void]$grid.Children.Add($descriptionBox)
        [System.Windows.Controls.Grid]::SetRow($descriptionBox, 3)

        # Add more controls for other properties as needed

        # Add Save and Cancel buttons to form
        $buttonPanel = New-Object System.Windows.Controls.StackPanel
        [System.Windows.Controls.Orientation]$buttonPanel.Orientation="Horizontal"
        [System.Windows.HorizontalAlignment]$buttonPanel.HorizontalAlignment="Right"
        [void]$grid.Children.Add($buttonPanel)
        [System.Windows.Controls.Grid]::SetRow($buttonPanel, 7)

        $saveButton = New-Object System.Windows.Controls.Button
        [string]$saveButton.Content="Save"
        [System.Windows.Thickness]$saveButton.Margin="0,0,5,0"
        [bool]$saveButton.IsDefault=$true
        [void]$buttonPanel.Children.Add($saveButton)

        $cancelButton = New-Object System.Windows.Controls.Button
        [string]$cancelButton.Content="Cancel"
        [bool]$cancelButton.IsCancel=$true
        [void]$buttonPanel.Children.Add($cancelButton)

         # Add event handlers for Save and Cancel buttons
         $saveButton.Add_Click({
             # Update selected switch with entered data
             $selectedSwitch.Name = $nameBox.Text
             $selectedSwitch.Description = $descriptionBox.Text
            #update the list of switches
                $switches = Read-Switches
            #replace the switch with matching unique ID with the updated switch
                $switches = $switches | ForEach-Object {
                    if ($_.UniqueID -eq $selectedSwitch.UniqueID) {
                        $selectedSwitch
                    } else {
                        $_
                    }
                }
            # Save changes to JSON file
             Write-Switches -switches $switches
             # Update ListView with new list of switches
             if ([string]::IsNullOrWhiteSpace($FilterBox.Text)) {
                 # No filter applied, show all switches
                 [System.Collections.IEnumerable]$SwitchList.ItemsSource=Read-Switches
             } else {
                 # Filter applied, show only matching switches
                 [string]$filterText=$FilterBox.Text

                 # Filter switches based on entered text in FilterBox
                 [array]$filteredSwitches=Read-Switches | Where-Object {
                     $_.Name -match [regex]::Escape($filterText) -or
                     $_.Description -match [regex]::Escape($filterText) -or
                     $_.IPAddress -match [regex]::Escape($filterText) -or
                     $_.Location -match [regex]::Escape($filterText) -or
                     $_.Tags -match [regex]::Escape($filterText)
                 }

                 # Update ListView with filtered list of switches
                 [System.Collections.IEnumerable]$SwitchList.ItemsSource=$filteredSwitches
             }



             # Close form
             $form.Close()
         })

         # Show form as dialog and wait for user input
         $form.ShowDialog()
    }
})

# Add event handlers for Delete and Connect buttons
$DeleteButton.Add_Click({
    # Get selected switches from ListView
    $selectedSwitches = $SwitchList.SelectedItems
    # for each switch in selected switches Remove selected switch from the list based on unique ID match
    $switches = Read-Switches
    $switches = $switches | ForEach-Object {
        if ($selectedSwitches.UniqueID -eq $_.UniqueID) {
            $switches.Remove($selectedSwitches)
        } else {
            $_
        }
    }


    
    

    # Update ListView with new list of switches
    if ([string]::IsNullOrWhiteSpace($FilterBox.Text)) {
        # No filter applied, show all switches
        [System.Collections.IEnumerable]$SwitchList.ItemsSource=$switches
    } else {
        # Filter applied, show only matching switches
        [string]$filterText=$FilterBox.Text

        # Filter switches based on entered text in FilterBox
        [array]$filteredSwitches=$switches | Where-Object {
            $_.Name -match [regex]::Escape($filterText) -or
            $_.Description -match [regex]::Escape($filterText) -or
            $_.IPAddress -match [regex]::Escape($filterText) -or
            $_.Location -match [regex]::Escape($filterText) -or
            $_.Tags -match [regex]::Escape($filterText)
        }

        # Update ListView with filtered list of switches
        [System.Collections.IEnumerable]$SwitchList.ItemsSource=$filteredSwitches
    }

    # Save changes to JSON file
    Write-Switches -switches $switches
    $switches = Read-Switches

})

$ConnectButton.Add_Click({
    # Get selected switches from ListView
    $selectedSwitches = $SwitchList.SelectedItems

    # Connect to each selected switch
    foreach ($switch in $selectedSwitches) {
        connectSwitch $switch
    }
})


# Load switches from JSON file into ListView
$SwitchList.ItemsSource = Read-Switches

# Show window
$window.ShowDialog()