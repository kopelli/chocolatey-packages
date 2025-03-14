@{
  Severity              = @('Error', 'Warning', 'Information', 'ParseError')
  IncludeRules          = @()
  ExcludeRules          = @(
    'PSAvoidGlobalVars' # Automatic Update depends on global variables to define behavior
  )
  CustomRulePath        = @()
  IncludeDefaultRules   = $true
  RecurseCustomRulePath = $false
  Rules                 = @{
    PSAlignAssignmentStatement                = @{
      Enable         = $true
      CheckHashtable = $true
    }
    PSAvoidExclaimOperator                    = @{
      Enable = $true
    }
    PSAvoidLongLines                          = @{
      Enable            = $true
      MaximumLineLength = 200
    }
    PSAvoidUsingCmdletAliases                 = @{
      AllowList = @()
    }
    PSAvoidSemicolonAsLineTerminators         = @{
      Enable = $true
    }
    PSAvoidUsingDoubleQuotesForConstantString = @{
      Enable = $true
    }
    PSPlaceCloseBrace                         = @{
      Enable             = $true
      NoEmptyLineBefore  = $true
      IgnoreOneLineBlock = $true
      NewLineAfter       = $true
    }
    PSPlaceOpenBrace                          = @{
      Enable             = $true
      OnSameLine         = $true
      IgnoreOneLineBlock = $true
      NewLineAfter       = $true
    }
    PSPlaceCommentHelp                        = @{
      Enable                  = $true
      ExportedOnly            = $true
      BlockComment            = $true
      VSCodeSnippetCorrection = $true
      Placement               = 'end'
    }
    PSReviewUnusedParameters                  = @{
      CommandsToTraverse = @()
    }
    PSUseCompatibleCmdlets                    = @{
      Compatibility = @('core-6.1.0-windows')
    }
    PSUseCompatibleCommands                   = @{
      Enable         = $true
      TargetProfiles = @('win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core')
      IgnoreCommands = @('Resolve-Path')
    }
    PSUseCompatibleSyntax                     = @{
      Enable         = $true
      TargetVersions = @('7.0')
    }
    PSUseCompatibleTypes                      = @{
      Enable         = $true
      TargetProfiles = @('win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core')
      IgnoreTypes    = @()
    }
    PSUseConsistentIndentation                = @{
      Enable              = $true
      IndentationSize     = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
      Kind                = 'space'
    }
    PSUseConsistentWhitespace                 = @{
      Enable                                  = $true
      CheckInnerBrace                         = $true
      CheckOpenBrace                          = $true
      CheckOpenParen                          = $true
      CheckOperator                           = $false # This cannot be enabled with PSAlignAssignmentStatement
      CheckPipe                               = $true
      CheckPipeForRedundantWhitespace         = $true
      CheckSeparator                          = $true
      CheckParameter                          = $true
      IgnoreAssignmentOperatorInsideHashTable = $false
    }
    PSUseCorrectCasing                        = @{
      Enable = $true
    }
    PSUseSingularNouns                        = @{
      Enable        = $true
      NounAllowList = @('Data', 'Windows', 'Metadata')
    }
  }
}