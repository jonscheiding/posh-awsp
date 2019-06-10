Import-Module -Force .\posh-awsprofiles.psm1

Describe "Get-AWSProfile" {
  BeforeEach {
    $Env:AWS_PROFILE = "some_profile"
  }

  It "Sets the specified profile when one is provided" {
    Set-AWSProfile -ProfileName "some_other_profile"
    $Env:AWS_PROFILE | Should Be "some_other_profile"
  }

  It "Clears the profile when null is provided" {
    Set-AWSProfile -ProfileName $null
    $Env:AWS_PROFILE | Should Be $null
  }

  AfterEach {
    if($null -ne $Env:AWS_PROFILE) {
      Remove-Item Env:\AWS_PROFILE
    }
  }
}