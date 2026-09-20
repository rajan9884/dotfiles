# Dual-GitHub SSH helpers — work (rj9884) vs personal (rajan9884).
# Run once per repo: `git-work` or `git-personal`.
# They set the repo-local identity AND rewrite origin to the right SSH host,
# so you never get auth conflicts between accounts.
#
#   Clone fresh:
#     git clone git@github-work:ORG/REPO.git
#     git clone git@github-personal:USER/REPO.git
#   Fix an existing repo:
#     cd REPO && git-work      # or git-personal
#   Check:
#     git-whoami

git-work() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo"; return 1; }
  git config user.name "rj9884"
  git config user.email "rj.vidyagyan@gmail.com"
  local url
  url=$(git remote get-url origin 2>/dev/null) || url=""
  if [ -n "$url" ]; then
    # https://github.com/...            -> git@github-work:...
    # git@github.com:...                -> git@github-work:...
    # git@github-personal:...           -> git@github-work:...
    url=$(printf '%s' "$url" | sed -e 's#^https://github\.com/#git@github-work:#' -e 's#^git@github\.com:#git@github-work:#' -e 's#^git@github-personal:#git@github-work:#')
    git remote set-url origin "$url"
  fi
  echo "→ work identity (rj9884 <rj.vidyagyan@gmail.com>)"
  git-whoami
}

git-personal() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo"; return 1; }
  git config user.name "rajan9884"
  git config user.email "rajan.dev.jaiswal@gmail.com"
  local url
  url=$(git remote get-url origin 2>/dev/null) || url=""
  if [ -n "$url" ]; then
    # https://github.com/...            -> git@github-personal:...
    # git@github.com:...                -> git@github-personal:...
    # git@github-work:...               -> git@github-personal:...
    url=$(printf '%s' "$url" | sed -e 's#^https://github\.com/#git@github-personal:#' -e 's#^git@github\.com:#git@github-personal:#' -e 's#^git@github-work:#git@github-personal:#')
    git remote set-url origin "$url"
  fi
  echo "→ personal identity (rajan9884 <rajan.dev.jaiswal@gmail.com>)"
  git-whoami
}

git-whoami() {
  echo "user.name  = $(git config user.name 2>/dev/null || echo '(unset)')"
  echo "user.email = $(git config user.email 2>/dev/null || echo '(unset)')"
  echo "origin     = $(git remote get-url origin 2>/dev/null || echo '(no origin)')"
}

# Keep both SSH keys loaded without prompting every shell.
if command -v ssh-add >/dev/null 2>&1; then
  for k in "$HOME/.ssh/id_ed25519_work" "$HOME/.ssh/id_ed25519_personal"; do
    [ -f "$k" ] && ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$k" 2>/dev/null | awk '{print $2}')" || ssh-add "$k" 2>/dev/null
  done
  unset k
fi
