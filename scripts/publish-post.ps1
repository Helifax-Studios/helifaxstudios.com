param(
  [Parameter(Mandatory=$true)][string]$RepoPath,
  [Parameter(Mandatory=$true)][string]$TitleFile,
  [Parameter(Mandatory=$true)][string]$BodyFile,
  [Parameter(Mandatory=$false)][string]$TagsFile = ""
)

$ErrorActionPreference = "Stop"

function Read-TextFile([string]$p){
  if ([string]::IsNullOrWhiteSpace($p)) { return "" }
  if (!(Test-Path $p)) { return "" }
  return (Get-Content $p -Raw -Encoding UTF8)
}

function Normalize-Tags([string]$t){
  if ([string]::IsNullOrWhiteSpace($t)) { return @() }
  return $t.Split(",") |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" } |
    Select-Object -Unique
}

$postsPath = Join-Path $RepoPath "posts\posts.json"
if (!(Test-Path $postsPath)) { throw "posts.json not found at: $postsPath" }

$title = (Read-TextFile $TitleFile).Trim()
$body  = (Read-TextFile $BodyFile).Trim()
$tagsRaw = (Read-TextFile $TagsFile).Trim()

if ([string]::IsNullOrWhiteSpace($title)) { throw "Title is empty." }
if ([string]::IsNullOrWhiteSpace($body))  { throw "Body is empty." }

# Read existing posts array
$jsonText = Get-Content $postsPath -Raw -Encoding UTF8
$posts = @()
if (-not [string]::IsNullOrWhiteSpace($jsonText)) {
  $parsed = $jsonText | ConvertFrom-Json
  if ($parsed -is [System.Collections.IEnumerable]) { $posts = @($parsed) }
}

$date = (Get-Date).ToString("yyyy-MM-dd")

$newPost = [PSCustomObject]@{
  title = $title
  date  = $date
  tags  = @(Normalize-Tags $tagsRaw)
  body  = $body   # Markdown text stored as-is
}

$updated = @($newPost) + $posts
$updated | ConvertTo-Json -Depth 8 | Set-Content $postsPath -Encoding UTF8

Push-Location $RepoPath
try{
  git add "posts/posts.json"
  $msg = "blog: $date - $title"
  git commit -m $msg
  git push
} finally {
  Pop-Location
}

Write-Output "Posted: $title"
