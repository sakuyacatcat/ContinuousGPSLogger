#!/bin/zsh

# Exit on error (-e), undefined vars (-u), and pipeline failures (-o pipefail)
set -euxo pipefail

# Disable Xcode macro fingerprint validation to prevent spurious build errors
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
