[CmdletBinding()]
param()
begin {
    Import-Module Chocolatey-AU -Force
    Set-StrictMode -Version 3.0

    # Configurable Values
    # =============================================================================
    $githubOwner = 'hairyhenderson'
    $githubRepository = 'gomplate'

    $packageMetadata = [ordered]@{
        id = 'gomplate.portable'
        version = '«REPLACED»'
        packageSourceUrl = '«REPLACED»'
        title = 'gomplate (Portable)'
        authors = '«REPLACED»'
        projectUrl = '«REPLACED»'
        iconUrl = 'https://rawcdn.githack.com/hairyhenderson/gomplate/main/docs/static/images/gomplate.png'
        licenseUrl = '«REPLACED»'
        requireLicenseAcceptance = 'true'
        projectSourceUrl = '«REPLACED»'
        docsUrl = 'https://docs.gomplate.ca/'
        mailingListUrl = '«REPLACED»'
        bugTrackerUrl = '«REPLACED»'
        tags = '«REPLACED»'
        summary = ''
        description = ''
        releaseNotes = $null
        owners = $null
    }

    # End Configuration
    # =============================================================================

    $githubApiRoot = "https://api.github.com/repos/$githubOwner/$githubRepository"
    $filesToRemove = @()

    function Update-PackageMetadata {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [AUPackage]$Package,
            [Parameter(Mandatory = $true)]
            [hashtable]$Metadata
        )
        begin {
            $xmlDoc = $Package.NuspecXml
            $metadataNode = $Package.NuspecXml.package.metadata
        }
        process {
            $Metadata.Keys | ForEach-Object -Process {
                $nodeName = $_
                $value = $Metadata[$nodeName]
                $node = $metadataNode.metadata[$nodeName]
                if ($null -ne $value) {
                    if ($null -eq $node) {
                        $node = $xmlDoc.CreateElement($nodeName)
                        $metadataNode.AddChild($node)
                    }
                    $node.InnerText = $value
                } else {
                    if ($null -ne $node) {
                        $metadataNode.RemoveChild($node)
                    }
                }
            }
        }
    }
}
process {
    function global:au_BeforeUpdate {
        param(
            [AUPackage]$Package
        )

        Update-PackageMetadata -Package $Package -Metadata $packageMetadata
    }

    function global:au_SearchReplace {
        param()

        @{
            ".\tools\chocolateyinstall.ps1" = @{
                "(?i)(^\s*\`$url\s*=\s*)'[^']*'(.*)$" = "`${1}'$($Latest.URL32)'`${2}"
                "(?i)(^\s*\`$url64\s*=\s*)'[^']*'(.*)$" = "`${1}'$($Latest.URL64)'`${2}"
                "(?i)(^\s*checksum\s*=\s*)'[^']*'(.*)$" = "`${1}'$($Latest.Checksum32 ?? '«INVALID»')'`${2}"
                "(?i)(^\s*checksum64\s*=\s*)'[^']*'(.*)$" = "`${1}'$($Latest.Checksum64 ?? '«INVALID»')'`${2}"
            }
            ".\tools\chocolateyuninstall.ps1" = @{}
            ".\tools\chocolateybeforemodify.ps1" = @{}
            ".\tools\VERIFICATION.txt" = @{}
        }
    }

    function global:au_AfterUpdate {
        param(
            [AUPackage]$Package
        )
    }

    function global:au_GetLatest {
        param()

        function out-verbose {
            $input | ForEach-Object {
                Write-Verbose -Message "[au_GetLatest] $_"
            }
        }

        $repoInfo = Invoke-RestMethod -Uri $githubApiRoot
        $repoInfo | out-verbose

        $releasesUrl = $repoInfo.releases_url -replace '\{.*\}',''
        $contributorsUrl = $repoInfo.contributors_url
        $issueUrl = "$($repoInfo.html_url)/issues"
        $discussions = "$($repoInfo.html_url)/discussions"

        $packageMetadata.projectUrl = $repoInfo.homepage
        $packageMetadata.summary = $repoInfo.description
        $packageMetadata.description = '...fill in later...' #TODO: Get from README?
        $packageMetadata.projectSourceUrl = $repoInfo.html_url
        $packageMetadata.tags = @($repoInfo.topics) + @($githubRepository)
        $packageMetadata.bugTrackerUrl = $repoInfo.has_issues -eq 'true' ? $issueUrl : $null

        # TODO: Discussions are available via the GraphQL api, not REST.
        # - https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions
        $packageMetadata.mailingListUrl = $repoInfo.has_discussions -eq 'true' ? $discussions : $null


        $communityProfileUrl = "$githubApiRoot/community/profile"
        $communityProfile = Invoke-RestMethod -Uri $communityProfileUrl
        $packageMetadata.licenseUrl = $communityProfile.files.license.html_url


        $knownBotUsers = @('renovate-bot', 'dependabot-support')
        $contributors = Invoke-RestMethod -Uri $contributorsUrl | ForEach-Object { $_ | Where-Object -FilterScript { $_.type -eq 'User' -and $knownBotUsers -notcontains $_.login } | Select-Object -Property login,contributions,url }
        $totalContributions = $contributors | Select-Object -ExpandProperty contributions | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $contributors | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name PercentageOfContributions -Value (($_.contributions / $totalContributions) * 100)}
        $contributorsOfNote = $contributors | Where-Object -FilterScript { $_.PercentageOfContributions -gt 1 } | ForEach-Object { Invoke-RestMethod -Uri $_.url } | Select-Object -ExpandProperty name
        $packageMetadata.authors = @($contributorsOfNote) -join ", "


        $branchName = $(git rev-parse --abbrev-ref HEAD)
        $remotes = $(
            try {
                git remote -v | Select-String -Pattern "^(?<name>[^\s]+)\s+(?<url>[^\s]+)\s+\(fetch\)$" -NoEmphasis | Select-Object -Property @{Name='Name';Expression={$_.Matches.Groups | Where-Object -FilterScript { $_.Name -eq 'name' } | Select-Object -ExpandProperty Value}},@{Name='Url';Expression={$_.Matches.Groups | Where-Object -FilterScript { $_.Name -eq 'url' } | Select-Object -ExpandProperty Value }}
            } catch {
                @()
            }
        )
        $remote = $remotes |
            ForEach-Object {
                $item = $_
                # TODO: apply remote name precidence. Typically 'origin' would be the one to use, but not necessarily the case.
                $item | Add-Member -MemberType NoteProperty -Name SortOrder -Value [int]::MinValue

                $browserUrl = $null
                switch -Regex ($item.Url) {
                    "^git@github\.com:(?<user_or_org>[\w\.-]+)/(?<repo>[\w\.-]+)\.git$" {
                        # This regex is based on from https://stackoverflow.com/a/59082561
                        $userOrOrg = $Matches['user_or_org']
                        $repo = $Matches['repo']
                        $browserUrl = "https://github.com/$userOrOrg/$repo"
                    }
                    default {
                        throw "Unable to determine what the browser friendly URL should be for the value '$($item.Url)'"
                    }
                }

                if ($null -ne $browserUrl) {
                    $item | Add-Member -MemberType NoteProperty -Name BrowserUrl -Value $browserUrl
                }
                $item
            } |
            Sort-Object -Property SortOrder,Name |
            Select-Object -First 1
        $repositoryPath = $PSScriptRoot | Resolve-Path -Relative -RelativeBasePath "$(git rev-parse --show-toplevel)"
        $packageSourceUrl = [uri]::new([uri]::new("$($remote.BrowserUrl)/tree/$branchName/"), $repositoryPath)
        "Package source: $packageSourceUrl" | out-verbose
        $packageMetadata.packageSourceUrl = $packageSourceUrl
        #TODO: Update $packageMetadata.packageSourceUrl by using `git remote get-url origin`
        # - parse 'git@github.com:kopelli/chocolatey-packages.git' to https...
        # - otherwise 'https://github.com/kopelli/chocolatey-packages.git'
        # - append the current location to the end of the path

        #TODO: Account for pagination by analyzing the 'link' HTTP header in the response...
        # - https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api?apiVersion=2022-11-28
        $releases = Invoke-RestMethod -Uri $releasesUrl
        $versionRegex = "(?<version>(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)$"
        $releaseStreams = [ordered]@{}
        $releases | ForEach-Object {
            $release = $_
            if ($release.draft -eq 'true') {
                Write-Host "Release '$($release.name)' is in draft mode. Skipping this release for distribution."
                return;
            }

            $versionParts = $release.tag_name | Select-String -Pattern $versionRegex | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups
            $semver = @{
                Version = $versionParts | Where-Object -FilterScript { $_.Name -eq 'version' } | Select-Object -ExpandProperty Value
                Major = $versionParts | Where-Object -FilterScript { $_.Name -eq 'major' } | Select-Object -ExpandProperty Value
                Minor = $versionParts | Where-Object -FilterScript { $_.Name -eq 'minor' } | Select-Object -ExpandProperty Value
                Patch = $versionParts | Where-Object -FilterScript { $_.Name -eq 'patch' } | Select-Object -ExpandProperty Value
                Prerelease = $versionParts | Where-Object -FilterScript { $_.Name -eq 'prerelease' -and $_.Success -eq $true } | Select-Object -ExpandProperty Value
                BuildMetadata = $versionParts | Where-Object -FilterScript { $_.Name -eq 'buildmetadata' -and $_.Success -eq $true } | Select-Object -ExpandProperty Value
            }

            [array]$assetUrls = $release.assets | Where-Object -FilterScript { $_.name -Match "\.exe$" } | Select-Object -ExpandProperty browser_download_url
            $checksumRegex = "checksums-v?$($semver.Version)(_sha256)?\.txt$"
            $checksumFileUrl = $release.assets | Where-Object -FilterScript { $_.name -Match $checksumRegex } | Sort-Object -Property name | Select-Object -First 1 -ExpandProperty browser_download_url
            if ($null -eq $checksumFileUrl){
                throw [System.NullReferenceException]"Using the regex '$checksumRegex', could not find the checksum file among the assets: `n$(@($release.assets | Select-Object -ExpandProperty name) -join ",`n")"
            }
            $tempChecksumFile = [System.IO.Path]::GetTempFileName()
            $filesToRemove += @($tempChecksumFile)

            function New-TemporaryFile {
                param(
                    [Parameter()]
                    $Directory = '',
                    [Parameter()]
                    [switch]
                    $NoDirectorySuffix,
                    [Parameter()]
                    $Filename = $null
                )
                $tempPath = [System.IO.Path]::GetTempPath()
                $tempDirectory = [System.IO.Path]::GetRandomFileName()
                $tempFilename = [System.IO.Path]::GetRandomFileName()
            }

            function ConvertTo-ParameterString {
                [CmdletBinding()]
                param(
                    [Parameter(Position = 0, ValueFromPipeline = $true)]
                    $dictionary
                )
                $dictionary.Keys | ForEach-Object {
                    $key = $_
                    $value = $dictionary[$key]
                    $valueType = $value.GetType().Name

                    switch ($valueType) {
                        'String' {
                            "-$key `"$value`""
                        }
                        default {
                            throw "Cannot handle a value of type '$valueType'"
                        }
                    }
                }
            }
            function Select-NamedRegexGroups {
                [CmdletBinding()]
                param(
                    [Parameter()]
                    $Pattern,
                    [Parameter()]
                    $Path
                )

                "Select-NamedRegexGroups $($PSBoundParameters | ConvertTo-ParameterString)" | out-verbose
                $matchedValues = Select-String -Pattern $Pattern -Path $Path -NoEmphasis
                $groups = $matchedValues |
                            Select-Object -ExpandProperty Matches |
                            Select-Object -ExpandProperty Groups
                $namedGroups = $groups | Where-Object -FilterScript { $_.Name -notmatch '\d+' }
                $namedGroups
            }
            Invoke-WebRequest $checksumFileUrl -OutFile $tempChecksumFile -UseBasicParsing
            $checksum32 = Select-NamedRegexGroups -Pattern "(?<checksum>[0-9a-f]+)\s+.*-386\.exe$" -Path $tempChecksumFile |
                            Where-Object -FilterScript { $_.Name -eq 'checksum' } |
                            Select-Object -ExpandProperty Value
            $checksum64 = Select-NamedRegexGroups -Pattern "(?<checksum>[0-9a-f]+)\s+.*-amd64\.exe$" -Path $tempChecksumFile |
                            Where-Object -FilterScript { $_.Name -eq 'checksum' } |
                            Select-Object -ExpandProperty Value

            $releaseStream = @{
                Name =         $release.name
                Version =      $semver.Version
                URL32 =        $assetUrls | Where-Object -FilterScript { $_ -Match "-386\.exe$" }
                Checksum32 =   $checksum32
                URL64 =        $assetUrls | Where-Object -FilterScript { $_ -Match "-amd64\.exe$" }
                Checksum64 =   $checksum64
                IsPreRelease = $release.prerelease -eq 'true'
                BrowserUrl =   $release.html_url
            }
            "$($release.name) -> $($release.tag_name)" | out-verbose
            $releaseStreams[$release.name] = $releaseStream
        }

        @{
            Streams = $releaseStreams
        }
    }

    #$DebugPreference = 'Continue'
    Update-Package -ChecksumFor none -NoReadMe
}
end {
    $filesToRemove | ForEach-Object {
        Remove-Item -Path $_ -ErrorAction SilentlyContinue | Out-Null
    }
}
