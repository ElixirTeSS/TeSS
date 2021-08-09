# Version Change Log
The sections below refer to the release tags for this repository:

---
## [Version 1.2.1](https://github.com/nrmay/TeSS/releases/tag/v1.2.1)

Theme: *Mid-Sprint Bug Fixes*

- Bug Fixes:
  - [Event activity log display #76](https://github.com/nrmay/TeSS/issues/76)
  - [Materials dictionary fields #108](https://github.com/nrmay/TeSS/issues/108)
  - [Sitemap generate fails: #139](https://github.com/nrmay/TeSS/issues/139)

- Features:
  - [Enable/disable Topics Feature: #129](https://github.com/nrmay/TeSS/issues/129)
  - [Enable/disable Fairshare and Biotools: #147](https://github.com/nrmay/TeSS/issues/147)

---
## [Version 1.2.0](https://github.com/nrmay/TeSS/releases/tag/v1.2.0)  

Theme: *Materials Ready*

  - Material metadata updates.
  - Prepare production for input.

Changes implemented in this version (with issue numbers) are as follows:
- Update Materials Metadata: 
  - [Update Model and UI - Pass 1: #92](https://github.com/nrmay/TeSS/issues/92)
  - [Update Model and UI - Pass 2: #109](https://github.com/nrmay/TeSS/issues/109)
  
- Features:
  - [Update Subscriptions Feature: #110](https://github.com/nrmay/TeSS/issues/110)
  - [Enable Packages Feature: #111](https://github.com/nrmay/TeSS/issues/111)

- User Interface:
  - [Update and Balance Supporter Icons - Pass 2: #112](https://github.com/nrmay/TeSS/issues/112)
  - [Create Default Provider and Package Icons: #123](https://github.com/nrmay/TeSS/issues/123)

- Bug Fixes:
  - [Hide Workflow Tabs on User's Profile: #105](https://github.com/nrmay/TeSS/issues/105)
  - [Fix length of Material Cards: #107](https://github.com/nrmay/TeSS/issues/107)
  - [Fix Meta Tags for Twitter, etc.: #113](https://github.com/nrmay/TeSS/issues/113)
  - [Fix Subsets adding extra items: #115](https://github.com/nrmay/TeSS/issues/115)

- Project Management:
  - [Add Change Log: #127](https://github.com/nrmay/TeSS/issues/127)

---
## [Version 1.1.0](https://github.com/nrmay/TeSS/releases/tag/v1.1.0)  

Theme: *DReSA Initial Release*

Initial deployment of DReSA includes the following:

- DReSA Branding.
- Parameterize application text and configuration settings.
- Enable Feature Switching (Enable/Disable).  
  - Events
  - Materials
  - Providers
  - Workflows (disabled)
- Enable login via AAF OpenID Connect.
- Implement Google Analytics & Google Map.
- Screen Layout Fixes.

--- 
Note: to create a new version tag run the following commands in master branch
when the full version is deployed:
> git tag -a v*X.Y.Z* -m "*message*"  
> git tag -n  
> git push origin --tags

Where *X.Y.Z* is the major, minor, patch numbers and *message* is an optional version label.  
