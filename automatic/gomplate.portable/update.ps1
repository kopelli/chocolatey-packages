[CmdletBinding()]
param()

Import-Module Chocolatey-AU
$githubOwner = 'hairyhenderson'
$githubRepository = 'gomplate'

$githubApiRoot = "https://api.github.com/repos/$githubOwner/$githubRepository"

$packageMetadata = [ordered]@{
    id = 'gomplate.portable'
    version = '«REPLACED»'
    packageSourceUrl = '«REPLACED»'
    title = 'gomplate (Portable)'
    projectUrl = '«REPLACED»'
    iconUrl = 'https://rawcdn.githack.com/hairyhenderson/gomplate/main/docs/static/images/gomplate.png'
    licenseUrl = '«REPLACED»'
    requireLicenseAcceptance = $true
    projectSourceUrl = '«REPLACED»'
    docsUrl = 'https://'
    mailingListUrl = '«REPLACED»'
    bugTrackerUrl = '«REPLACED»'
    tags = '«REPLACED»'
    summary = ''
    description = ''
    releaseNotes = ''
}

function global:au_BeforeUpdate {
    param(
        $Package
    )
}

function global:au_SearchReplace {
    param()

    @{
        ".\tools\chocolateyinstall.ps1" = @{}
        ".\tools\chocolateyuninstall.ps1" = @{}
        ".\tools\chocolateybeforemodify.ps1" = @{}
        ".\tools\VERIFICATION.txt" = @{}
    }
}

function global:au_AfterUpdate {
    param(
        $Package
    )
}

function global:au_GetLatest {
    param()

    $repoInfo = Invoke-RestMethod -Uri $githubApiRoot

    $packageMetadata.projectUrl = $repoInfo.homepage
    $packageMetadata.summary = $repoInfo.description
    $packageMetadata.description = '' #TODO: Get from README?
    $packageMetadata.projectSourceUrl = $repoInfo.html_url
    $packageMetadata.tags = @($repoInfo.topics) + @($githubRepository)
    $packageMetadata.bugTrackerUrl = $repoInfo.has_issues -eq 'true' ? $repoInfo.issues_url.Remove('{...}') : $null
    
    # TODO: Discussions are available via the GraphQL api, not REST.
    # - https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions
    #$packageMetadata.mailingListUrl = $repoInfo.has_discussions -eq 'true' ? '' : ''

    # TODO: $packageMetadata.licenseUrl -- hunt down from the repo...

    $releases = Invoke-RestMethod -Uri $repoInfo.releases_url #TODO: Remove any `{...}` content

    $versionRegex = "((\d+)(\.\d+){1,3}(\-[a-z]+[0-9]+)?)$"
    #TODO: Update $packageMetadata.packageSourceUrl by using `git remote get-url origin`
    # - parse 'git@github.com:kopelli/chocolatey-packages.git' to https...
    # - otherwise 'https://github.com/kopelli/chocolatey-packages.git'
    # - append the current location to the end of the path

    #TODO: Get latest Version


    # respond with 'ignore' or HashTable
    # HashTable could have 'Streams', which takes precedence
}