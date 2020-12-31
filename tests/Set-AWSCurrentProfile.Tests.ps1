Import-Module -Force .\posh-awsp.psm1
Import-Module -Force .\tests\test-helpers.psm1

Describe "Set-AWSCurrentProfile" {
  BeforeEach {
    Save-Environment
    Set-Item Env:AWS_PROFILE "some_profile"
  }

  It "Sets the specified profile when one is provided" {
    Set-AWSCurrentProfile -ProfileName "some_other_profile"
    $Env:AWS_PROFILE | Should -Be "some_other_profile"
  }

  It "Clears the profile when the -Clear parameter is provided" {
    Set-AWSCurrentProfile -Clear
    $Env:AWS_PROFILE | Should -Be $null
  }

  AfterEach {
    Restore-Environment
  }
}
