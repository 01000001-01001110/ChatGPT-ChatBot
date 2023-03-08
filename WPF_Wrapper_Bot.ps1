function loadSeptember {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationCore, PresentationFramework
    $Xaml = @"
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            Height="314"
            Width="344"
            WindowStyle="None"
            ResizeMode="CanResize"
            AllowsTransparency="True"
            WindowStartupLocation="CenterScreen"
            Background="Transparent"
            Foreground="Azure"
            FontFamily="Century Gothic"
            FontSize="14"
            Opacity="1" >
        <Window.Resources>
            <Style TargetType="Button" x:Key="RoundButton">
                <Style.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="5" />
                    </Style>
                </Style.Resources>
            </Style>
            <Style TargetType="{x:Type TextBox}">
                <Style.Resources>
                    <Style TargetType="{x:Type Border}">
                        <Setter Property="CornerRadius" Value="3" />
                    </Style>
                </Style.Resources>
            </Style>
        </Window.Resources>
        <Border CornerRadius="5" BorderBrush="#333333" BorderThickness="5" Background="#333333">
            <Grid>
                <Grid Height="30" HorizontalAlignment="Stretch" VerticalAlignment="Top" Background="#FF474747">
                    <Border CornerRadius="5" BorderBrush="#004b99" BorderThickness="5" Background="#004b99">
                        <StackPanel Orientation="Horizontal">
                            <Button Name="close_btn" Foreground="Azure" Height="20" Width="20" Background="Transparent" Content="X" FontSize="14" Margin="10,0,0,0" FontWeight="Bold" Style="{DynamicResource RoundButton}"/>
                            <Button Name="minimize_btn" Foreground="Azure" Height="20" Width="20" Background="Transparent" Content="-" FontSize="14" Margin="2 0 0 0" FontWeight="Bold" Style="{DynamicResource RoundButton}"/>
                            <TextBlock Text="September Bot " Foreground="Azure" Margin="160 0 0 0"/>
                        </StackPanel>
                    </Border>
                </Grid>
                <Button Background="#007acc" Foreground="black" FontSize="20" Style="{DynamicResource RoundButton}" Name="send_Btn" Content="&gt;" HorizontalAlignment="Left" Margin="264,261,0,0" VerticalAlignment="Top" Height="33" Width="60"/>
                <TextBox Name="textBox" HorizontalAlignment="Left" Margin="7,261,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="252" Height="33"/>
                <TextBox Name="responseTXTBox" Margin="10,64,10,69" 
                                    VerticalScrollBarVisibility="Auto"
                                    Height="Auto"
                                    Width="Auto" TextWrapping="Wrap" />
                <CheckBox Content="Voice On/Off" Name="voiceCheckBox" Foreground="Azure" HorizontalAlignment="Left" Margin="10,240,0,0" VerticalAlignment="Top"/>
                <Button Background="#007acc" Foreground="black" Style="{DynamicResource RoundButton}" Name="export_Btn" Content="Export" HorizontalAlignment="Left" Margin="250,35,0,0" VerticalAlignment="Top" Height="24" Width="74"/>
                <CheckBox Content="Male Voice?" Name="voiceChoiceCheckBox" Foreground="Azure" HorizontalAlignment="Left" Margin="218,240,0,0" VerticalAlignment="Top" IsChecked="False"/>
            </Grid>
        </Border>
    </Window>
"@
    #-------------------------------------------------------------#
    #                      Window Function                        #
    #-------------------------------------------------------------#
    $Window = [Windows.Markup.XamlReader]::Parse($Xaml)
    
    [xml]$xml = $Xaml
    
    $xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) } 
    
    #-------------------------------------------------------------#
    #                  Define Window Move                         #
    #-------------------------------------------------------------#
    
    #Click and Drag WPF window without title bar (ChromeTab or whatever it is called)
    $Window.Add_MouseLeftButtonDown({
        $Window.DragMove()
    })
       
    #-------------------------------------------------------------#
    #                      Define Buttons                         #
    #-------------------------------------------------------------#
    
    #Custom Close Button
    $close_btn.add_Click({
        $Window.Close();
    })

    # Define boolean variable for voice
    $voiceEnabled = $false

    #Custom Minimize Button
    $minimize_btn.Add_Click({
        $Window.WindowState = 'Minimized'
    })

    # Add event listener to voice checkbox
    $voiceCheckBox.Add_Click({
        $voiceEnabled = $voiceCheckBox.IsChecked
    })

    $responseTXTBox = $Window.FindName("responseTXTBox")

    #Summon September
    Function Summon-September {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content,
            #Need to add your key here. 
            [string]$APIKey = "sk-#########################################",
            #This model is their new chat beta, and 10% less costs to use than the old completions model
            [string]$Model = "gpt-3.5-turbo-0301",
            #tag the user so the system can flag inappropriate use
            [string]$Role = "user",
            #Format the bot before the user's input. 
            [string]$Prefix = "Your prompt starts here:"
        )
        #Added Voice
        ([Reflection.Assembly]::LoadWithPartialName("System.Speech")) > null
        $Input = $Prefix
        $Content = "$Input $($ExecutionContext.InvokeCommand.ExpandString($Content))"
        $uri = "https://api.openai.com/v1/chat/completions"
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $APIKey"
        }
        $body = @{
            "model" = $Model
            "messages" = @(
                @{
                    "role" = $Role
                    "content" = $Content
                }
            )
        } | ConvertTo-Json
        # Count tokens
        $tokenCount = ($Input + $APIKey + $Model + $Content).Length / 4
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        $text = $response.choices[0].message.content
        $responseTXTBox.AppendText("$text`n")
        $responseTXTBox.AppendText("`n") # add newline before each response
    
        # Check if voice is enabled and the appropriate gender voice is selected
        if ($voiceCheckBox.IsChecked -and $voiceChoiceCheckBox.IsChecked) {
            $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $synthesizer.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Male)
            $synthesizer.Rate = .75
            $synthesizer.Speak($text)
        }
        elseif ($voiceCheckBox.IsChecked) {
            $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $synthesizer.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
            $synthesizer.Rate = .75
            $synthesizer.Speak($text)
        }
        
        return $text
    }
    
    #Add KeyDown event to the text box
    $textBox.Add_KeyDown({
        param($sender, $e)
        #Check if Enter is pressed and the text box is not empty
        if ($e.Key -eq 'Enter' -and $textBox.Text -ne '') {
            $send_Btn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent, $send_Btn)))
            Summon-September -Content "$($textBox.Text)" -ErrorAction SilentlyContinue
            $textBox.Clear() #clear the text box after sending the message
        }
    })

        #Custom Send Button
        $send_Btn.Add_Click({
            Summon-September -Content "$($textBox.Text)" -ErrorAction SilentlyContinue
            $textBox.Clear() #clear the text box after sending the message
        })

    # Add click event to export button
    $export_Btn.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Filter = "Text File (*.txt)|*.txt"
        $dialog.DefaultExt = ".txt"
        $dialog.Title = "Export Chat History"
        $result = $dialog.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $filePath = $dialog.FileName
            Set-Content -Path $filePath -Value $responseTXTBox.Text # Export the contents of the text box
            Invoke-Item $filePath
        }
    })

    #-------------------------------------------------------------#
    #                   Define Conditionals                       #
    #-------------------------------------------------------------#
    
    #Show Window, without this, the script will never initialize the OSD of the WPF elements.
    $Window.ShowDialog()
}
    
loadSeptember
