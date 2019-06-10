function Save-Environment {
  $Script:SavedEnvironment = @{}
  Get-ChildItem Env: | ForEach-Object {
    $Script:SavedEnvironment[$_.Name] = $_.Value
  }
}

function Restore-Environment {
  Get-ChildItem Env: | ForEach-Object {
    Remove-Item Env:$($_.Key)
  }

  $Script:SavedEnvironment.Keys | ForEach-Object {
    Set-Item Env:$($_) $Script:SavedEnvironment[$_]
  }
}
