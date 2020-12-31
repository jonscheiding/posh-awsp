#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '4.0.2' }

$Result = Invoke-Pester -PassThru

if($null -eq $Result) {
  throw "No test results were returned."
}

if($Result.FailedCount -gt 0) {
  throw "$($Result.FailedCount) tests failed."
}
