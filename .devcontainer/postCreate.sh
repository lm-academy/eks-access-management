#!/usr/bin/env bash
# Runs on container create. Safe to run more than once (idempotent).
set -euo pipefail

MARKER="# >>> eks-access-management tool completions >>>"

# Install bash-completion if it is missing. kubectl's bash completion relies on
# it. The dpkg check keeps this a no-op once it is installed.
if ! dpkg -s bash-completion >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends bash-completion
fi

# Hand the persisted credential and kubeconfig named volumes to the container
# user. Harmless to repeat.
sudo chown -R vscode:vscode /home/vscode/.aws /home/vscode/.kube 2>/dev/null || true

# Match the course zsh look: Oh My Zsh (preinstalled in the base image) with the
# robbyrussell theme, the git and aws plugins, and command syntax highlighting.
if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.zshrc" ]; then
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Third-party syntax-highlighting plugin: clone once. Non-fatal if offline.
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
      || echo "warn: zsh-syntax-highlighting clone failed (non-fatal)"
  fi

  # Set the theme and plugin list. Idempotent: re-running sets the same values.
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$HOME/.zshrc"
  sed -i 's/^plugins=.*/plugins=(git aws zsh-syntax-highlighting)/' "$HOME/.zshrc"
fi

# Make zsh the default login shell so every new terminal starts in it, including
# outside VS Code. Idempotent (skips if already zsh) and non-fatal.
ME="$(id -un)"
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "$(getent passwd "$ME" | cut -d: -f7)" != "$ZSH_BIN" ]; then
  sudo chsh -s "$ZSH_BIN" "$ME" || echo "warn: could not set zsh as default shell (non-fatal)"
fi

# Wire up completions for bash, only if not already present.
# The heredoc is quoted, so command substitutions run when the shell starts.
if [ -f "$HOME/.bashrc" ] && ! grep -qF "$MARKER" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" <<'EOF'

# >>> eks-access-management tool completions >>>
[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion
if command -v kubectl >/dev/null; then
  source <(kubectl completion bash)
  alias k=kubectl
  complete -o default -F __start_kubectl k
fi
command -v helm >/dev/null && source <(helm completion bash)
command -v aws_completer >/dev/null && complete -C aws_completer aws
command -v terraform >/dev/null && complete -C "$(command -v terraform)" terraform
# <<< eks-access-management tool completions <<<
EOF
fi

# Wire up completions for zsh, only if not already present (base image ships zsh).
if [ -f "$HOME/.zshrc" ] && ! grep -qF "$MARKER" "$HOME/.zshrc"; then
  cat >> "$HOME/.zshrc" <<'EOF'

# >>> eks-access-management tool completions >>>
autoload -Uz compinit bashcompinit && compinit && bashcompinit
if command -v kubectl >/dev/null; then
  source <(kubectl completion zsh)
  alias k=kubectl
  compdef k=kubectl
fi
command -v helm >/dev/null && source <(helm completion zsh)
command -v aws_completer >/dev/null && complete -C aws_completer aws
command -v terraform >/dev/null && complete -C "$(command -v terraform)" terraform
# <<< eks-access-management tool completions <<<
EOF
fi

# Print the pinned versions as a sanity check.
terraform version
aws --version
kubectl version --client
helm version
