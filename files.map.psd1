# Source (repo-relative) → target (machine paths)
# $Home is expanded at runtime. Theme definitions live inside wezterm.lua;
# ~/.wezterm-theme-index is intentionally NOT mapped (per-machine state).

@{
  Files = @(
    @{
      Source = 'files/wezterm.lua'
      Target = '$Home\.wezterm.lua'
    }
    @{
      Source = 'files/wezterm-pwsh.ps1'
      Target = '$Home\config\wezterm-pwsh.ps1'
    }
    @{
      Source = 'files/wezterm-keys.md'
      Target = '$Home\config\wezterm-keys.md'
    }
    @{
      Source = 'files/powershell-profile-snippet.ps1'
      Target = '$Home\config\powershell-profile-snippet.ps1'
    }
  )

  # Only the Mono family WezTerm actually uses (not Propo / NL / full set).
  Fonts = @{
    SourceDir = 'fonts/JetBrainsMonoNerdFontMono'
    Pattern   = 'JetBrainsMonoNerdFontMono-*.ttf'
    # User-install location (no admin)
    TargetDir = '$env:LOCALAPPDATA\Microsoft\Windows\Fonts'
  }
}
