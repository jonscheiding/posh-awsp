Import-Module Pester

$Result = Invoke-Pester -PassThru
if($Result.FailedCount -gt 0) {
  throw "$($Result.FailedCount) tests failed."
}
