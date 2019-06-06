Import-Module -Force .\posh-awsprofiles.psm1

Describe "Get-AWSProfile" {
  It "Returns 'default' if there is no profile set" {
    $profile = Get-AWSProfile
    $profile | Should Be "default"
  }

  Context "With profile set" {
    BeforeEach {
      $Env:AWS_PROFILE = "profile_specified"
    }

    It "Returns the specified profile" {
      $profile = Get-AWSProfile
      $profile | Should Be "profile_specified"
    }

    AfterEach {
      Remove-Item Env:\AWS_PROFILE
    }
  }
}
