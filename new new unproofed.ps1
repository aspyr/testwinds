Add-Type -AssemblyName PresentationFramework

# Define functions for reading and writing JSON file
function Read-Switches {
    if (Test-Path -Path switches.json) {
        Get-Content -Path switches.json | ConvertFrom-Json
    } else {
        @()
    }
}

function Write-Switches([object[]]$switches) {
    $switches | ConvertTo-Json | Out-File -FilePath switches.json
}

# Create WPF window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Switch Manager" SizeToContent="WidthAndHeight">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <TextBox Grid.Row="0" Margin="5" Name="FilterBox" />
        <Button Grid.Row="1" Margin="5" Name="SelectAllButton" Content="Select All" />
        <ListView Grid.Row="2" Margin="5" Name="SwitchList">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="50">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate>
                                <CheckBox IsChecked="{Binding IsSelected}" />
                            </DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" />
                    <GridViewColumn Header="Description" DisplayMemberBinding="{Binding Description}" />
                    <GridViewColumn Header="IP Address" DisplayMemberBinding="{Binding IPAddress}" />
                    <GridViewColumn Header="Location" DisplayMemberBinding="{Binding Location}" />
                    <GridViewColumn Header="Tags" DisplayMemberBinding="{Binding Tags}" />
                </GridView>
            </ListView.View>
        </ListView>
        <StackPanel Grid.Row="3" Margin="5" Orientation="Horizontal">
            <Button Margin="0,0,5,0" Name="<EUGPSCoordinates>AddButton</EUGPSCoordinates>">Add</Button>
            <Button Margin="<EUGPSCoordinates>0</EUGPSCoordinates>,0,<EUGPSCoordinates>5</EUGPSCoordinates>,0" Name="<EUGPSCoordinates>EditButton</EUGPSCoordinates>">Edit</Button>
            <Button Margin="<EUGPSCoordinates>0</EUGPSCoordinates>,0,<EUGPSCoordinates>5</EUGPSCoordinates>,0" Name="<EUGPSCoordinates>DeleteButton</EUGPSCoordinates>">Delete</Button>
            <Button Margin="<EUGPSCoordinates>0</EUGPSCoordinates>,0,<EUGPSCoordinates>0</EUGPSCoordinates>,0" HorizontalAlignment="<EUGPSCoordinates>Right</EUGPSCoordinates>" Name="<EUGPSCoordinates>ConnectButton</EUGPSCoordinates>">Connect</Button>
        </StackPanel>
    </Grid>
</Window>
"@


$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$window=[Windows.Markup.XamlReader]::Load( $reader )

# Get references to controls
$SwitchList=$window.FindName('SwitchList')
$FilterBox=$window.FindName('FilterBox')
$SelectAllButton=$window.FindName('SelectAllButton')
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

# Add event handlers for Select All and Add buttons
$SelectAllButton.Add_Click({
    # Toggle selection of all items in ListView
    $allSelected = $true
    foreach ($item in $SwitchList.Items) {
        if (!$item.IsSelected) {
            $allSelected = $false
            break
        }
    }

    foreach ($item in $SwitchList.Items) {
        $item.IsSelected = !$allSelected
    }
})

$AddButton.Add_Click({
    # Create form to add new switch
    $form = New-Object System.Windows.Window
    $form.Title = "Add Switch"
    $form.SizeToContent = "WidthAndHeight"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "5"
    $form.Content = $grid

    # Add controls for Name property
    [void]$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    [void]$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

    $nameLabel = New-Object System.Windows.Controls.Label
    [string]$nameLabel.Content="Name:"
    [void]$grid.Children.Add($nameLabel)
    [System.Windows.Controls.Grid]::SetRow($nameLabel, 0)

    $nameBox = New-Object System.Windows.Controls.TextBox
    [System.Windows.Thickness]$nameBox.Margin="0,0,0,5"
    [void]$grid.Children.Add($nameBox)

[System.Windows.Controls.Grid]::SetRow($nameBox, 1)

# Add controls for Description property
[void]$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
[void]$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

$descriptionLabel = New-Object System.Windows.Controls.Label
[string]$descriptionLabel.Content="Description:"
[void]$grid.Children.Add($descriptionLabel)
[System.Windows.Controls.Grid]::SetRow($descriptionLabel, 2)

$descriptionBox = New-Object System.Windows.Controls.TextBox
[System.Windows.Thickness]$descriptionBox.Margin="0,0,0,5"
[void]$grid.Children.Add($descriptionBox)
[System.Windows.Controls.Grid]::SetRow($descriptionBox, 3)

# Add controls for other properties as needed

# Add Save and Cancel buttons to form
[void]$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

$buttonPanel = New-Object System.Windows.Controls.StackPanel
[System.Windows.Controls.Orientation]$buttonPanel.Orientation="Horizontal"
[System.Windows.HorizontalAlignment]$buttonPanel.HorizontalAlignment="Right"
[void]$grid.Children.Add($buttonPanel)
[System.Windows.Controls.Grid]::SetRow($buttonPanel, 5)

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
     $newSwitch = New-Object PSObject -Property @{
         UniqueID = [guid]::NewGuid()
         Name = $nameBox.Text
         Description = $descriptionBox.Text
         IPAddress = ""
         Location = ""
         Tags = ""
         IsSelected = $false
     }

     # Add new switch to list of switches
     $switches = Read-Switches + $newSwitch

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
     Write-Switches $switches

     # Close form
     $form.Close()
 })

 # Show form as dialog and wait for user input
 $form.ShowDialog()
})

# Add event handlers for Edit and Delete buttons

# Load switches from JSON file into ListView and add IsSelected property to each switch object
$SwitchList.ItemsSource = (Read-Switches | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name IsSelected -Value $false; $_ })

# Show window
$window.ShowDialog()
