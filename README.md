# rFactor2 Manager Scripts

Powershell cmdlets and scripts for managing rFactor 2 servers.


# Usage

## Setup

Add the cmdlets to your powershell modules 

## Install content from Steam Workshop

Use the `Install-Rf2-Mod` cmdlet to install a mod:

  Install-Rf2-Mod <WORKSHOP_ID> -Path <RF2_INSTALL_PATH>

The script will download the mod content automatically from the workshop and add an extry to its internal DB. It will get the mod name from the Workshop page.

### Note on DLC

You must use the `-Dlc` flag when installing DLC content, you must also provide a `-Name` as the script is unable to get mod names for DLC items as they don't
have public workshop pages to scrape.

