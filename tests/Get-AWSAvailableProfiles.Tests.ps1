Import-Module -Force .\posh-awsp.psm1
Import-Module -Force .\tests\test-helpers.psm1

Describe "Get-AWSAvailableProfiles" {
  BeforeEach {
    Save-Environment
    Set-Item Env:AWS_CONFIG_FILE (Get-Item .\tests\config).FullName
  }

  $TestCases = @(
    @{ ProfileName = 'default' }
    @{ ProfileName = 'profile1' }
    @{ ProfileName = 'profile2' }
  )

  It "Contains 3 profiles" {
    $Profiles = Get-AWSAvailableProfiles
    $Profiles.Length | Should -Be 3
  }

  It "Contains the '<ProfileName>' profile" -TestCases $TestCases {
    param ($ProfileName)

    $Profiles = Get-AWSAvailableProfiles
    $ProfileName | Should -BeIn $Profiles
  }

  AfterEach {
    Restore-Environment
  }
}
