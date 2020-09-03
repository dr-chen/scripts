#!/usr/bin/env bash
# Hiding a Mac OSX Administrator Account and moving Administrator Home folders to hidden location

if [[ "$(/usr/bin/whoami)" != "root" ]]; then printf '\nMust be run as root!\n\n'; exit 1; fi

sudo mv /Users/Administrator /var/.Administrator

sudo chown -R Administrator /var/.Administrator

sudo rm -R /var/.Administrator/Public /var/.Administrator/Sites

sudo defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES

sudo defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array Administrator

sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This Some Company system is a company asset and therefore you should have no expectation of privacy in its use." 

echo "Administrator Account has been hidden from System Preferences Pane and in Finder."
echo "Login Window Message has been generated."