# Claude Code Power Pack — Setup Script (Windows PowerShell)
# https://github.com/ModernMustardSeed/claude-code-power-pack

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = "$env:USERPROFILE\.claude"
$SkillsDir = "$ClaudeDir\skills"

Write-Host ""
Write-Host "  Claude Code Power Pack - Setup" -ForegroundColor Cyan
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host ""

# Collect user info
$UserName = Read-Host "  Your name"
$UserEmail = Read-Host "  Your email"
$UserOrg = Read-Host "  Your organization (or press Enter to skip)"
if ([string]::IsNullOrWhiteSpace($UserOrg)) { $UserOrg = "Independent Developer" }

Write-Host ""
Write-Host "  Setting up for: $UserName <$UserEmail> @ $UserOrg" -ForegroundColor Green
Write-Host ""

# Create directories
Write-Host "  [1/7] Creating directory structure..."
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
$MemoryDir = "$ClaudeDir\projects\memory"
New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null

# Copy skills
Write-Host "  [2/7] Installing skills..."
$SkillCount = 0
$SkillDirs = @("core", "workflow", "productivity")
foreach ($category in $SkillDirs) {
    $CategoryPath = "$ScriptDir\skills\$category"
    if (Test-Path $CategoryPath) {
        Get-ChildItem -Directory $CategoryPath | ForEach-Object {
            $SkillFile = "$($_.FullName)\SKILL.md"
            if (Test-Path $SkillFile) {
                $DestDir = "$SkillsDir\$($_.Name)"
                New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
                Copy-Item $SkillFile "$DestDir\SKILL.md" -Force
                $SkillCount++
            }
        }
    }
}
Write-Host "         $SkillCount skills installed"

# Copy and customize CLAUDE.md
Write-Host "  [3/7] Creating root CLAUDE.md..."
$ClaudeMdPath = "$env:USERPROFILE\CLAUDE.md"
if (-not (Test-Path $ClaudeMdPath)) {
    $content = Get-Content "$ScriptDir\templates\CLAUDE.md" -Raw
    $content = $content -replace "YOUR_NAME", $UserName
    $content = $content -replace "YOUR_EMAIL", $UserEmail
    $content = $content -replace "YOUR_ORGANIZATION", $UserOrg
    Set-Content -Path $ClaudeMdPath -Value $content -Encoding UTF8
    Write-Host "         Created at ~/CLAUDE.md"
} else {
    Write-Host "         ~/CLAUDE.md already exists - skipping"
}

# Copy and customize MEMORY.md
Write-Host "  [4/7] Creating MEMORY.md brain boot sequence..."
$MemoryMdPath = "$MemoryDir\MEMORY.md"
if (-not (Test-Path $MemoryMdPath)) {
    $content = Get-Content "$ScriptDir\templates\MEMORY.md" -Raw
    $content = $content -replace "YOUR_NAME", $UserName
    $content = $content -replace "YOUR_EMAIL", $UserEmail
    $content = $content -replace "YOUR_ORGANIZATION", $UserOrg
    Set-Content -Path $MemoryMdPath -Value $content -Encoding UTF8
    Write-Host "         Created at $MemoryMdPath"
} else {
    Write-Host "         MEMORY.md already exists - skipping"
}

# Copy topic files
Write-Host "  [5/7] Creating topic files..."
Get-ChildItem "$ScriptDir\templates\topic-files\*.md" | ForEach-Object {
    $DestPath = "$MemoryDir\$($_.Name)"
    if (-not (Test-Path $DestPath)) {
        Copy-Item $_.FullName $DestPath
        Write-Host "         Created $($_.Name)"
    } else {
        Write-Host "         $($_.Name) already exists - skipping"
    }
}

# Copy keybindings
Write-Host "  [6/7] Setting up keybindings..."
$KeybindingsPath = "$ClaudeDir\keybindings.json"
if (-not (Test-Path $KeybindingsPath)) {
    Copy-Item "$ScriptDir\keybindings.json" $KeybindingsPath
    Write-Host "         Keybindings installed"
} else {
    Write-Host "         keybindings.json already exists - skipping"
}

# Summary
Write-Host "  [7/7] Verifying installation..."
$InstalledSkills = (Get-ChildItem -Recurse "$SkillsDir\*\SKILL.md" -ErrorAction SilentlyContinue).Count
$HasClaude = Test-Path $ClaudeMdPath
$HasMemory = Test-Path $MemoryMdPath
$TopicCount = (Get-ChildItem "$MemoryDir\*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "MEMORY.md" }).Count

Write-Host ""
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Skills installed:  $InstalledSkills"
Write-Host "  Root CLAUDE.md:    $HasClaude"
Write-Host "  MEMORY.md:         $HasMemory"
Write-Host "  Topic files:       $TopicCount"
Write-Host "  Keybindings:       $(Test-Path $KeybindingsPath)"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Edit ~/CLAUDE.md to add your projects"
Write-Host "  2. Edit MEMORY.md to add your project registry"
Write-Host "  3. Add per-project CLAUDE.md to each project (use templates\project-CLAUDE.md)"
Write-Host "  4. Copy stack modules from stacks\ into your topic files"
Write-Host "  5. Start a Claude Code session and run /boot"
Write-Host ""
Write-Host "  Recommended MCP servers:" -ForegroundColor Yellow
Write-Host "  - @anthropic/memory (persistent knowledge graph)"
Write-Host "  - @anthropic/github (PR and repo operations)"
Write-Host "  - @anthropic/sequential-thinking (complex reasoning)"
Write-Host "  - @anthropic/context7 (library documentation)"
Write-Host ""
Write-Host "  See mcp-guide\README.md for setup instructions."
Write-Host ""
