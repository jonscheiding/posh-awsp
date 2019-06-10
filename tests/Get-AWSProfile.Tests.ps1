Import-Module -Force .\posh-awsprofiles.psm1

Describe "Get-AWSProfile" {
  Context "With no profile set" {
    BeforeEach {
      if($null -ne $Env:AWS_PROFILE) {
        Remove-Item Env:\AWS_PROFILE
      }
    }

    It "Returns 'default'" {
      $profile = Get-AWSProfile
      $profile | Should Be "default"
    }
  }

  Context "With profile set" {
    BeforeEach {
      $Env:AWS_PROFILE = "some_profile"
    }

    It "Returns the specified profile" {
      $profile = Get-AWSProfile
      $profile | Should Be "some_profile"
    }

    AfterEach {
      Remove-Item Env:\AWS_PROFILE
    }
  }
}
