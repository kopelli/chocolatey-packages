# AU Packages Template: https://github.com/majkinetor/au-packages-template
[CmdletBinding()]
[Diagnositics.CodeAnalysis.SuppressMessage(
  'PSUseDeclaredVarsMoreThanAssignments',
  '',
  Justification = 'Global variables are exported for interaction with Automatic Updates')]
param(
  [string] $Name,
  [string] $ForcedPackages,
  [string] $Root = "$PSScriptRoot\automatic"
)
begin {
  Import-Module -Name Chocolatey-AU

  # Create this file to consistently run this script locally.
  $envFile = Join-Path -Path $PSScriptRoot -ChildPath '.env.ps1'
  if (Test-Path $envFile) {
    . $envFile
  }

  $Options = [ordered]@{
    Timeout        = 100                                     #Connection timeout in seconds
    UpdateTimeout  = 1200                                    #Update timeout in seconds
    Threads        = 10                                      #Number of background jobs to use
    Push           = $Env:au_Push -eq 'true'                 #Push to chocolatey
    PluginPath     = "$(Join-Path -Path $PSScriptRoot -ChildPath 'au_plugins')" #Path to user plugins
    ForcedPackages = $ForcedPackages -split ' '
    BeforeEach     = {
      param($PackageName, $Options )
      $p = $Options.ForcedPackages | Where-Object -FilterScript { $_ -match "^${PackageName}(?:\:(.+))*$" }
      if (-not $p) { return }

      $global:au_Force = $true
      $global:au_Version = ($p -split ':')[1]
    }
  }

  $Options | Add-PluginOption -PluginName 'Report' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_Report -eq $true) {
      @{
        Type   = 'markdown'                                   #Report type: markdown or text
        Path   = "$PSScriptRoot\Update-AUPackages.md"         #Path where to save the report
        Params = @{                                          #Report parameters:
          Github_UserRepo = $Env:github_user_repo         #  Markdown: shows user info in upper right corner
          NoAppVeyor      = $false                            #  Markdown: do not show AppVeyor build shield
          UserMessage     = '[History](#update-history)'       #  Markdown, Text: Custom user message to show
          NoIcons         = $false                            #  Markdown: don't show icon
          IconSize        = 32                                #  Markdown: icon size
          Title           = ''                                #  Markdown, Text: TItle of the report, by default 'Update-AUPackages'
        }
      }
    }
  )
  $Options | Add-PluginOption -PluginName 'History' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_History -eq $true) {
      @{
        Lines           = 30                                          #Number of lines to show
        Github_UserRepo = $Env:github_user_repo             #User repo to be link to commits
        Path            = "$PSScriptRoot\Update-History.md"            #Path where to save history
      }
    }
  )
  $Options | Add-PluginOption -PluginName 'Gist' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_Gist -eq $true) {
      @{
        Id     = $Env:gist_id                               #Your gist id; leave empty for new private or anonymous gist
        ApiKey = $Env:github_api_key                        #Your github api key - if empty anoymous gist is created
        Path   = "$PSScriptRoot\Update-AUPackages.md", "$PSScriptRoot\Update-History.md"       #List of files to add to the gist
      }
    }
  )
  $Options | Add-PluginOption -PluginName 'Git' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_Git -eq $true) {
      @{
        User     = ''                                       #Git username, leave empty if github api key is used
        Password = $Env:github_api_key                      #Password if username is not empty, otherwise api key
      }
    }
  )
  $Options | Add-PluginOption -PluginName 'RunInfo' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_RunInfo -eq $true) {
      @{
        Exclude = 'password', 'apikey'                      #Option keys which contain those words will be removed
        Path    = "$PSScriptRoot\update_info.xml"           #Path where to save the run info
      }
    }
  )
  $Options | Add-PluginOption -PluginName 'Mail' -PluginOptions $(
    if ($env:au_UpdateAll_Plugin_Mail -eq $true -and $Env:mail_user) {
      @{
        To          = $Env:mail_user
        Server      = $Env:mail_server
        UserName    = $Env:mail_user
        Password    = $Env:mail_pass
        Port        = $Env:mail_port
        EnableSsl   = $Env:mail_enablessl -eq 'true'
        Attachment  = "$PSScriptRoot\update_info.xml"
        UserMessage = ''
        SendAlways  = $false                        #Send notifications every time
      }
    }
  )

  if ($ForcedPackages) {
    Write-Information "FORCED PACKAGES: $ForcedPackages"
  }

  function Add-PluginOption {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
      [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
      [System.Collections.Specialized.OrderedDictionary]
      $Options,

      [Parameter(Mandatory = $true)]
      [string]
      $PluginName,

      [Parameter(Mandatory = $false)]
      [hashtable]
      $PluginOptions,

      [switch]
      $PassThru
    )
    process {
      if ($null -ne $Options[$PluginName]) {
        throw [System.InvalidOperationException]::new("The configuration for plugin '$PluginName' has already been defined.")
      }

      if ($PluginOptions -isnot [hashtable]) {
        $Options[$PluginName] = $null
      }

      $Options[$PluginName] = $PluginOptions

      if ($PassThru) {
        $Options
      }
    }
  }
}
process {
  $global:au_Root = $Root                                    #Path to the AU packages
  $global:info = Update-AUPackages -Name $Name -Options $Options -Verbose ($VerbosePreference -eq 'Continue')
  #Uncomment to fail the build on AppVeyor on any package error
  #if ($global:info.error_count.total) { throw 'Errors during update' }
}
end {
}
