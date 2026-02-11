# CLAUDE.md - BCApps Repository Guide

## Overview

This is the **Microsoft Dynamics 365 Business Central Applications (BCApps)** repository. It contains the source code for the System Application, Business Foundation, developer tools, and first-party apps, all written in **AL (Application Language)** and built with **AL-Go for GitHub**.

- **License**: MIT
- **Platform version**: 28.0.0.0
- **Publisher**: Microsoft
- **Build framework**: [AL-Go for GitHub](https://github.com/microsoft/AL-Go)

## Repository Structure

```
/BCApps
  /.github/              GitHub Actions workflows, PR templates, AL-Go settings
  /.azuredevops/         Azure DevOps pipeline configs (mirroring, security)
  /.devcontainer/        VS Code dev container configuration
  /build/
    /projects/           AL-Go project definitions (7 projects)
    /scripts/            PowerShell build, test, and automation scripts
    Packages.json        NuGet and artifact dependency versions
  /src/
    /System Application/ Core system modules (115+ modules)
      /App/              Production code (facade + implementation pattern)
      /Test/             Unit tests
      /Test Library/     Shared test utilities
      /Partner Test/     Partner-contributed tests
    /Business Foundation/ Foundation business logic (NoSeries, AuditCodes, etc.)
      /App/              Production code
      /Test/             Unit tests
      /Test Library/     Shared test utilities
    /Tools/              Developer tools
      /Test Framework/   Test Runner, Test Libraries, Test Stability Tools
      /AI Test Toolkit/  AI/Copilot testing capabilities
      /Performance Toolkit/ Performance measurement tools
    /Apps/W1/            First-party apps (Shopify, EDocument, PowerBI, etc.)
    /rulesets/           Code analysis rule configurations
  build.ps1              Main build entry point
  CONTRIBUTING.md        Contribution guidelines
  LOCAL_DEV_ENV.md       Local development environment setup
  CODEOWNERS             Code ownership by team
```

## Build and Development

### Prerequisites

- Docker Desktop with Windows containers
- BcContainerHelper PowerShell module: `Install-Module BCContainerHelper -AllowPrerelease`

### Building

The primary build command uses `build.ps1`, which runs `localDevEnv.ps1` for the specified AL-Go project inside a Docker container:

```powershell
# Build a specific project
.\build.ps1 -ALGoProject "System Application"

# Build with auto-generated credentials
.\build.ps1 -ALGoProject "System Application" -AutoFill
```

### Local Development Environment

```powershell
# Create dev container + configure VS Code
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'

# Create container + publish System Application
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\App'

# Create container + publish System Application with all tests
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' -ProjectPaths '.\src\System Application\*'
```

### AL-Go Projects

Located in `build/projects/`, each project has `.AL-Go/settings.json` and `.AL-Go/localDevEnv.ps1`:

| Project | Description |
|---------|-------------|
| System Application | System App, Business Foundation, and Tools (compile only) |
| System Application Modules | Individual system modules |
| System Application Tests | System App + Business Foundation tests |
| Business Foundation Tests | Business Foundation test suite |
| Apps (W1) | First-party world-wide apps (multi-country builds) |
| Performance Toolkit Tests | Performance testing framework |
| Test Stability Tools | Test stability utilities |

### CI/CD

GitHub Actions workflows in `.github/workflows/`:

- **CICD.yaml** - Full CI/CD on push to `main` and `releases/*`
- **PullRequestHandler.yaml** - PR validation on `main`, `releases/*`, `features/*`
- **_BuildALGoProject.yaml** - Reusable build template
- **PowerShell.yaml** - PSScriptAnalyzer + Pester tests on `.ps1`/`.psm1` changes
- **WorkitemValidation.yaml** - Validates linked work items

PRs trigger a full build when changes touch `build/*`, `src/rulesets/*`, or workflow files (defined in `fullBuildPatterns` in `.github/AL-Go-Settings.json`).

## Code Analysis and Quality

All analyzers are enabled and configured to treat violations as errors:

- **CodeCop** - Code style and best practices (AA rules)
- **AppSourceCop** - AppSource compliance (AS rules)
- **UICop** - UI/UX standards (AW rules)
- **PerTenantExtensionCop** - PTE rules (PTE rules)
- **Compiler** - Compiler warnings/errors (AL rules)
- **Analyzer** - Custom analysis rules (AD rules)

Rulesets are in `src/rulesets/`. The main `ruleset.json` includes all others with `generalAction: "Error"`. A few rules are explicitly suppressed with documented justifications.

## AL Coding Conventions

### File and Object Naming

- **Files**: `ObjectName.ObjectType.al` (e.g., `Email.Codeunit.al`, `EmailImpl.Codeunit.al`, `EmailConnector.Interface.al`)
- **Objects**: PascalCase in quotes (e.g., `"Email"`, `"Email Impl"`, `"Azure AD Graph User"`)
- **Permission sets**: `"Module - Role"` format (e.g., `"Email - Admin"`, `"Email - Edit"`, `"Email - Read"`)

### File Header (required on all files)

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
```

### Namespace and Imports

```al
namespace System.Email;

using System;
using System.Security.AccessControl;
```

### Facade + Implementation Pattern

Every module follows a strict facade/implementation separation:

**Facade** (public API - e.g., `Email.Codeunit.al`):
```al
codeunit 8901 Email
{
    Access = Public;

    /// <summary>
    /// Saves a draft email in the Outbox.
    /// </summary>
    /// <param name="EmailMessage">The email message to save.</param>
    procedure SaveAsDraft(EmailMessage: Codeunit "Email Message")
    begin
        EmailImpl.SaveAsDraft(EmailMessage);
    end;

    var
        EmailImpl: Codeunit "Email Impl";
}
```

**Implementation** (internal - e.g., `EmailImpl.Codeunit.al`):
```al
codeunit 8900 "Email Impl"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "Sent Email" = rimd,
                  tabledata "Email Outbox" = rimd;

    procedure SaveAsDraft(EmailMessage: Codeunit "Email Message")
    begin
        // Actual business logic here
    end;
}
```

### XML Documentation

All public procedures must have XML documentation:

```al
/// <summary>
/// Sends the email using the specified account.
/// </summary>
/// <param name="EmailMessage">The email message to send.</param>
/// <param name="EmailAccountId">The ID of the email account.</param>
/// <param name="EmailConnector">The email connector to use.</param>
/// <returns>True if the email was successfully sent.</returns>
/// <error>The email message has already been queued.</error>
procedure Send(EmailMessage: Codeunit "Email Message"; EmailAccountId: Guid; EmailConnector: Enum "Email Connector"): Boolean
```

### Variables and Labels

- **Variables**: PascalCase (e.g., `EmailOutbox`, `EmailMessageImpl`)
- **Labels with Locked**: Use suffix `Lbl`, `Msg`, `Err`, `Txt`
  ```al
  var
      EmailCategoryLbl: Label 'Email', Locked = true;
      EmailMessageDoesNotExistMsg: Label 'The email message has been deleted by another user.';
      InvalidEmailAccountErr: Label 'The email account is not valid.';
  ```

### Module Directory Structure

Each module in `src/System Application/App/` follows:
```
ModuleName/
  app.json               Module metadata, dependencies, ID ranges
  README.md              Module description and main entities
  permissions/           Permission sets (Admin, Edit, Read, Objects)
  src/                   Source code organized by feature
```

### Preprocessor Directives

Version-gated code uses `#if not CLEAN##` directives (where ## = version number):

```al
#if not CLEAN26
    [Obsolete('Use the new overload instead.', '26.0')]
    procedure OldMethod(): Boolean
    begin
        // Deprecated code
    end;
#endif
```

Active preprocessor symbols: `CLEAN25`, `CLEAN26`, `CLEAN27`, `CLEAN28`.

### Permissions and Security

- Use `InherentPermissions = X` and `InherentEntitlements = X` on implementation codeunits
- Declare explicit `Permissions` for table data access
- Permission sets use `R`(ead), `I`(nsert), `M`(odify), `D`(elete) abbreviations
- Permission set files go in `permissions/` subdirectory

### Tables

- Use `DataClassification` on all fields
- Declare `Clustered = true` on primary key
- Use `TableType = Temporary` for data transfer objects
- Set `Access = Internal` for internal tables

## Testing Conventions

### Test Structure

Tests mirror the source structure:
- `/src/System Application/Test/` - Module tests
- `/src/System Application/Test Library/` - Reusable test utilities
- `/src/System Application/Partner Test/` - Partner tests

### Test Codeunit Pattern

```al
codeunit 132589 "Advanced Settings Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    [Test]
    procedure TestAdvancedSettingsOpens()
    var
        PermissionsMock: Codeunit "Permissions Mock";
        AdvancedSettings: TestPage "Advanced Settings";
    begin
        // [GIVEN] User has view permissions
        PermissionsMock.Set('Adv. Settings View');

        // [WHEN] System action is triggered
        AdvancedSettings.Trap();
        SystemActionTriggers.OpenGeneralSetupExperience();

        // [THEN] Advanced settings page opens
        AdvancedSettings.Close();
    end;
}
```

Key conventions:
- Test codeunit IDs are in the 132xxx range
- Use `Subtype = Test` on the codeunit
- Test procedures use `[Test]` attribute
- Method names: `Test[ScenarioDescription]`
- Comments follow **Given/When/Then** (AAA) pattern: `// [GIVEN]`, `// [WHEN]`, `// [THEN]`
- Use `PermissionsMock` to test permission scenarios
- Use `TestPage` for UI testing

### PowerShell Tests

PowerShell tests use Pester framework:
- Located in `build/scripts/tests/`
- Run with: `.\build\scripts\tests\runTests.ps1`

## Editor Settings

From `.devcontainer/BCApps/devcontainer.json`:
- **Tab size**: 3 spaces
- **Insert spaces**: true (no tabs)
- **Trim trailing whitespace**: true
- **Insert final newline**: true

## Pull Request Process

1. An approved GitHub issue must exist before creating a PR
2. PR must link to the issue with `Fixes #<issue-number>`
3. All CI checks must pass (build, code analysis, tests)
4. Code owner approval required (see `CODEOWNERS`)
5. Microsoft performs final validation before merge

PR template (`PULL_REQUEST_TEMPLATE.md`):
```
#### Summary <!-- general summary of changes -->
#### Work Item(s)
Fixes #
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `build.ps1` | Main build entry point |
| `.github/AL-Go-Settings.json` | Global AL-Go build configuration |
| `src/rulesets/ruleset.json` | Master ruleset (includes all sub-rulesets) |
| `.devcontainer/BCApps/devcontainer.json` | Dev container setup |
| `build/Packages.json` | NuGet/artifact dependency versions |
| `CONTRIBUTING.md` | Contribution guidelines |
| `LOCAL_DEV_ENV.md` | Local dev environment setup guide |
| `CODEOWNERS` | Code ownership definitions |

## Code Ownership

| Path/Pattern | Team |
|-------------|------|
| `/src` (default) | `@microsoft/d365-bc-app-required` |
| `/src/rulesets/` | `@microsoft/d365-bc-app-rulesets` |
| `app.json` | `@microsoft/d365-bc-engineering-systems` + `@microsoft/d365-bc-app-required` |
| `*.ps1`, `/build`, `/.github`, `.AL-Go/` | `@microsoft/d365-bc-engineering-systems` |
| `**/Permissions/`, `*.Permissionset.al` | `@microsoft/d365-bc-app-permissions` |
| `dotnet.al` | `@microsoft/d365-bc-app-security` |
| `/src/System Application/App/AI` | `@microsoft/d365-bc-copilot-toolkit` |
