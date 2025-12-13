param(
  [Parameter(Mandatory=$true)][string]$RepoPath,
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Body,
  [string]$Tags = ""
)

$ErrorActionPreference = "Stop"

function Normalize-Tags([string]$t){
  if ([string]::IsNullOrWhiteSpace($t)) { return @() }
  return $t.Split(",") |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" } |
    Select-Object -Unique
}

$postsPath = Join-Path $RepoPath "posts\posts.json"
if (!(Test-Path $postsPath)) {
  throw "posts.json not found at: $postsPath"
}

# Read + parse JSON
$jsonText = Get-Content $postsPath -Raw -Encoding UTF8
$posts = @()
if (-not [string]::IsNullOrWhiteSpace($jsonText)) {
  $parsed = $jsonText | ConvertFrom-Json
  if ($parsed -is [System.Collections.IEnumerable]) { $posts = @($parsed) }
}

# Build new post
$date = (Get-Date).ToString("yyyy-MM-dd")
$newPost = [PSCustomObject]@{
  title = $Title.Trim()
  date  = $date
  tags  = @(Normalize-Tags $Tags)
  body  = $Body.Trim()
}

# Prepend newest post
$updated = @($newPost) + $posts

# Write prettified JSON
$updated | ConvertTo-Json -Depth 6 | Set-Content $postsPath -Encoding UTF8

# Git commit + push
Push-Location $RepoPath
try{
  git add "posts/posts.json"
  $msg = "blog: $date - $($newPost.title)"
  git commit -m $msg
  git push
} finally {
  Pop-Location
}

Write-Output "Posted: $($newPost.title)"
