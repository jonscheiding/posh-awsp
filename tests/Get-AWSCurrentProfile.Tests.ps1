Import-Module -Force .\posh-awsprofiles.psm1
Import-Module -Force .\tests\test-helpers.psm1

Describe "Get-AWSCurrentProfile" {
  Context "With no profile set" {
    BeforeEach {
      Save-Environment
      Remove-Item -ErrorAction Ignore Env:AWS_PROFILE
    }

    It "Returns 'default'" {
      $profile = Get-AWSCurrentProfile
      $profile | Should Be "default"
    }

    AfterEach {
      Restore-Environment
    }
  }

  Context "With profile set" {
    BeforeEach {
      Save-Environment
      Set-Item Env:AWS_PROFILE "some_profile"
    }

    It "Returns the specified profile" {
      $profile = Get-AWSCurrentProfile
      $profile | Should Be "some_profile"
    }

    AfterEach {
      Restore-Environment
    }
  }
}
