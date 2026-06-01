#!/usr/bin/env sh

set -eu

git config core.hooksPath scripts/git-hooks
echo "[Hooks] core.hooksPath=scripts/git-hooks configured for Smart Trainner Flutter."
