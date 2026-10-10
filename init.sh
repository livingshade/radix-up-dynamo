# radix-up project for Dynamo + SGLang development on the SGLang community cluster.
# Runs LOCALLY once per assigned node (see `radix-up --help`). Idempotent, so
# `radix-up setup <machine-id> --project dynamo-sglang` can re-run it.
set -euo pipefail
source "$RADIX_UP_LIB"

# files/ -> remote ~ (dotfiles, ~/bin helpers, and the gitignored .radix_env).
push files

remote <<'EOF'
set -euo pipefail

# Optional overrides go in ~/.radix_env (pushed from files/.radix_env).
if [[ -f ~/.radix_env ]]; then
  chmod 600 ~/.radix_env
  set -a; source ~/.radix_env; set +a
  grep -q radix_env ~/.bashrc 2>/dev/null || echo '[ -f ~/.radix_env ] && set -a && . ~/.radix_env && set +a' >> ~/.bashrc
fi
profile=~/.profile; [[ -f ~/.bash_profile ]] && profile=~/.bash_profile
grep -q bashrc "$profile" 2>/dev/null || echo '[ -n "$BASH_VERSION" ] && [ -f ~/.bashrc ] && . ~/.bashrc' >> "$profile"
grep -q 'HOME/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
chmod +x ~/bin/* 2>/dev/null || true

mkdir -p ~/.ssh && chmod 700 ~/.ssh
grep -q github.com ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null

git config --global user.name "${GIT_AUTHOR_NAME:-Banruo Liu}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-lichangxinlivingshade@gmail.com}"
# HTTPS pushes as livingshade when GH_TOKEN is set; the helper reads the
# variable at call time, so the token is never written into git config.
if [[ -n "${GH_TOKEN:-}" ]]; then
  git config --global credential.https://github.com.helper \
    '!f() { echo username=livingshade; echo "password=$GH_TOKEN"; }; f'
fi

DYNAMO_FORK="${DYNAMO_FORK:-https://github.com/livingshade/dynamo.git}"
cd ~
[[ -d dynamo ]] || git clone -q "$DYNAMO_FORK" dynamo
git -C dynamo remote get-url upstream >/dev/null 2>&1 \
  || git -C dynamo remote add upstream https://github.com/ai-dynamo/dynamo.git
git -C dynamo fetch -q upstream main || true

# Image pull and model predownload run in the background so SSH is usable
# right away. Progress: ~/prefetch.log
if ! pgrep -f dynamo-prefetch >/dev/null; then
  nohup ~/bin/dynamo-prefetch > ~/prefetch.log 2>&1 &
fi

echo "setup done on $RADIX_MACHINE_ID (rank $RADIX_NODE_RANK); prefetch log: ~/prefetch.log"
EOF
