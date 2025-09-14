#!/bin/bash
# 💪 .bashrc on steroids with oh-my-posh and useful functions

# Exit if the shell is not interactive
[[ $- != *i* ]] && return

# === Basic settings === ⚙️
# History
HISTCONTROL=ignoreboth
HISTSIZE=999999
HISTFILESIZE=999999
shopt -s histappend
shopt -s checkwinsize

# === Oh-My-Posh === ✨

# 👉 Install oh-my-posh if it's not installed:
#
# curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
# sudo mkdir -p /usr/share/oh-my-posh/themes
# sudo mv /root/.cache/oh-my-posh/themes/* /usr/share/oh-my-posh/themes/
# sudo curl -fsSL https://git.recwebnetwork.com/oh-my-posh/themes/recweb.omp.json -o /usr/share/oh-my-posh/themes/recweb.omp.json
# sudo chmod -R a+r /usr/share/oh-my-posh/themes

eval "$(oh-my-posh init bash --config /usr/share/oh-my-posh/themes/recweb.omp.json)"

# === Useful aliases === 🔖
# Colors for commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Shortcuts for ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Other useful aliases
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# Git (if you use it)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias release='git_release'
alias push='git_push'


# === Load additional files === 📂
# Custom aliases
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Hestia (if you use it)
[ -f /etc/profile.d/hestia.sh ] && source /etc/profile.d/hestia.sh

# Command not found handler
if [ -x /usr/lib/command-not-found ]; then
    command_not_found_handle()
    {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi

# === Useful functions === 🧰
# Extract archives
extract()
{
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a directory and enter it
mkcd()
{
    mkdir -p "$1" && cd "$1"
}

# === Git release helper (semver) === 🏷️🚀
git_release()
{
    # Config
    local DEFAULT_START="v1.0.0"   # starting point if no tag exists
    local REMOTE="origin"
    local BRANCH=""
    local SET_VERSION=""
    local INCREMENT="auto"         # auto | major | minor | patch
    local ALLOW_DIRTY="no"
    local DRY_RUN="no"
    local MESSAGE=""

    # Arg parsing
    for arg in "$@"
    do
        case "$arg" in
            --v=*|--version=*)
                SET_VERSION="${arg#*=}"
                ;;
            --major)
                INCREMENT="major"
                ;;
            --minor)
                INCREMENT="minor"
                ;;
            --patch)
                INCREMENT="patch"
                ;;
            --start=*)
                DEFAULT_START="${arg#*=}"
                [[ "$DEFAULT_START" =~ ^v ]] || DEFAULT_START="v$DEFAULT_START"
                ;;
            --remote=*)
                REMOTE="${arg#*=}"
                ;;
            --branch=*)
                BRANCH="${arg#*=}"
                ;;
            --allow-dirty)
                ALLOW_DIRTY="yes"
                ;;
            -n|--dry-run)
                DRY_RUN="yes"
                ;;
            -m=*)
                MESSAGE="${arg#*=}"
                ;;
            -m)
                shift
                MESSAGE="$1"
                ;;
            -h|--help)
                cat <<'EOF'
Usage: git_release [--v=1.2.3 | --major | --minor | --patch] [--start=1.0.0]
                   [--remote=origin] [--branch=<name>] [--allow-dirty] [-n|--dry-run]
                   [-m "message"]

Without options: autoincrement (vX.Y.0 after vX.(Y-1).9, otherwise vX.Y.(Z+1))
Examples:
  git_release                 # v1.0.1 -> v1.0.2, v1.0.9 -> v1.1.0
  git_release --v=1.2.0       # set directly to v1.2.0
  git_release --minor         # bump minor (reset patch)
  git_release --major         # bump major (reset minor/patch)
  git_release -n              # show what it would do, without modifying repo
EOF
                return 0
                ;;
        esac
    done

    # 1) Is it a Git repo?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "❌ You are not in a Git repository."
        return 1
    fi

    # 2) Current branch (if not given)
    if [ -z "$BRANCH" ]
    then
        BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    fi

    # 3) Clean?
    if [ "$ALLOW_DIRTY" = "no" ]
    then
        if ! git diff --quiet || ! git diff --cached --quiet
        then
            echo "❌ Working tree has uncommitted changes. Use --allow-dirty if intentional."
            return 1
        fi
    fi

    # 4) Last semver tag reachable from HEAD
    local LAST_TAG
    LAST_TAG="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --merged HEAD | sort -V | tail -n1)"

    # 5) Determine the future tag
    local NEXT_TAG
    if [ -n "$SET_VERSION" ]
    then
        # manually set version
        [[ "$SET_VERSION" =~ ^v ]] || SET_VERSION="v$SET_VERSION"
        if [[ ! "$SET_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
        then
            echo "❌ Invalid version: $SET_VERSION (expected: vX.Y.Z or X.Y.Z)"
            return 1
        fi
        NEXT_TAG="$SET_VERSION"
    else
        local BASE="${LAST_TAG:-$DEFAULT_START}"
        [[ "$BASE" =~ ^v ]] || BASE="v$BASE"
        if [[ ! "$BASE" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
        then
            echo "❌ Last tag is not semver (vX.Y.Z): $BASE"
            return 1
        fi

        local VER="${BASE#v}"
        local MAJOR MINOR PATCH
        IFS='.' read -r MAJOR MINOR PATCH <<< "$VER"

        case "$INCREMENT" in
            major)
                MAJOR=$((MAJOR + 1))
                MINOR=0
                PATCH=0
                ;;
            minor)
                MINOR=$((MINOR + 1))
                PATCH=0
                ;;
            patch)
                PATCH=$((PATCH + 1))
                ;;
            auto)
                # Your logic: 0..8 -> +1 patch; 9 -> bump minor, reset patch
                if [ "$PATCH" -ge 9 ]
                then
                    PATCH=0
                    if [ "$MINOR" -ge 9 ]
                    then
                        MINOR=0
                        MAJOR=$((MAJOR + 1))
                    else
                        MINOR=$((MINOR + 1))
                    fi
                else
                    PATCH=$((PATCH + 1))
                fi
                ;;
        esac

        NEXT_TAG="v${MAJOR}.${MINOR}.${PATCH}"
    fi

    # 6) Avoid duplicates
    if git rev-parse "$NEXT_TAG" >/dev/null 2>&1
    then
        echo "❌ Tag $NEXT_TAG already exists."
        return 1
    fi

    local MSG="${MESSAGE:-$NEXT_TAG}"

    echo "➡️  Branch: $BRANCH"
    echo "➡️  Remote: $REMOTE"
    echo "➡️  Last tag: ${LAST_TAG:-(none)}"
    echo "✅  Next tag: $NEXT_TAG"
    echo "📝  Message: $MSG"
    [ "$DRY_RUN" = "yes" ] && { echo "(dry-run) Not creating tag and not pushing."; return 0; }

    # 7) Create tag and push atomically
    if ! git tag -a "$NEXT_TAG" -m "$MSG"
    then
        echo "❌ Error in 'git tag'."
        return 1
    fi

    if ! git push --atomic "$REMOTE" "$BRANCH" "$NEXT_TAG"
    then
        echo "❌ Error in push. Deleting local tag created."
        git tag -d "$NEXT_TAG" >/dev/null 2>&1
        return 1
    fi

    echo "🎉 Done: $NEXT_TAG has been pushed to $REMOTE/$BRANCH."
}

# === Git quick push (add + commit random + push) === ⚡🐱
git_push()
{
    # Options
    local MSG=""                 # -m "message"
    local PREFIX="chore"         # --prefix=chore|feat|fix|docs|refactor|style|test|perf
    local REMOTE=""              # --remote=origin
    local BRANCH=""              # --branch=main
    local NO_VERIFY="no"         # --no-verify
    local SIGNOFF="no"           # --signoff
    local AMEND="no"             # --amend
    local DRY_RUN="no"           # -n | --dry-run

    # Parse args
    while [ $# -gt 0 ]
    do
        case "$1" in
            -m)
                shift
                MSG="$1"
                ;;
            -m=*)
                MSG="${1#*=}"
                ;;
            --msg=*)
                MSG="${1#*=}"
                ;;
            --prefix=*)
                PREFIX="${1#*=}"
                ;;
            --remote=*)
                REMOTE="${1#*=}"
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                ;;
            --no-verify)
                NO_VERIFY="yes"
                ;;
            --signoff)
                SIGNOFF="yes"
                ;;
            --amend)
                AMEND="yes"
                ;;
            -n|--dry-run)
                DRY_RUN="yes"
                ;;
            -h|--help)
                cat <<'EOF'
Usage: push [-m "message"] [--prefix=chore|feat|fix|docs|refactor|style|test|perf]
            [--remote=origin] [--branch=main] [--no-verify] [--signoff] [--amend]
            [-n|--dry-run]

Without options: stage everything, commit with a random message and push to upstream.
Examples:
  push
  push -m "feat: import products"
  push --prefix=fix
  push --no-verify
  push --amend               # amend the last commit
  push -n                    # show what it would do
EOF
                return 0
                ;;
        esac
        shift
    done

    # In a Git repository?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "❌ You are not in a Git repository."
        return 1
    fi

    # Current branch
    local CUR_BRANCH
    CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || CUR_BRANCH=""

    # Upstream (if any)
    local UPSTREAM REMOTE_FROM_UPSTREAM BRANCH_FROM_UPSTREAM SET_UPSTREAM=""
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1
    then
        UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u})"
        REMOTE_FROM_UPSTREAM="${UPSTREAM%/*}"
        BRANCH_FROM_UPSTREAM="${UPSTREAM#*/}"
    fi

    # Final REMOTE/BRANCH
    local FINAL_REMOTE FINAL_BRANCH
    FINAL_REMOTE="${REMOTE:-${REMOTE_FROM_UPSTREAM:-origin}}"
    FINAL_BRANCH="${BRANCH:-${BRANCH_FROM_UPSTREAM:-${CUR_BRANCH}}}"
    if [ -z "$BRANCH_FROM_UPSTREAM" ]
    then
        SET_UPSTREAM="-u"
    fi

    # Any changes to push?
    if [ -z "$(git status --porcelain)" ] && [ "$AMEND" = "no" ]
    then
        echo "ℹ️  No changes to push."
        return 0
    fi

    # Add all (respects .gitignore)
    echo "➕  git add -A"
    [ "$DRY_RUN" = "yes" ] || git add -A

    # Random message if not provided
    if [ -z "$MSG" ] && [ "$AMEND" = "no" ]
    then
        # simple generator: adj-noun + entropy
        local ADJ=(quick neat bold crisp calm bright tiny solid sleek sharp clean smart fresh tidy)
        local NOUN=(update tweak sync patch change polish refactor touch bump adjust tidyup hotfix)
        local R1=$((RANDOM % ${#ADJ[@]}))
        local R2=$((RANDOM % ${#NOUN[@]}))
        local RANDHEX
        RANDHEX="$(openssl rand -hex 2 2>/dev/null || echo $RANDOM)"
        MSG="${PREFIX}: ${ADJ[$R1]}-${NOUN[$R2]}-${RANDHEX}"
    elif [ -z "$MSG" ] && [ "$AMEND" = "yes" ]
    then
        # when amend without message => keep previous message (--no-edit)
        :
    fi

    # Commit flags
    local COMMIT_ARGS=()
    [ "$SIGNOFF" = "yes" ] && COMMIT_ARGS+=("--signoff")
    [ "$NO_VERIFY" = "yes" ] && COMMIT_ARGS+=("--no-verify")

    # Commit
    if [ "$AMEND" = "yes" ]
    then
        if [ -n "$MSG" ]
        then
            echo "📝  git commit --amend -m \"$MSG\" ${COMMIT_ARGS[*]}"
            [ "$DRY_RUN" = "yes" ] || git commit --amend -m "$MSG" "${COMMIT_ARGS[@]}"
        else
            echo "📝  git commit --amend --no-edit ${COMMIT_ARGS[*]}"
            [ "$DRY_RUN" = "yes" ] || git commit --amend --no-edit "${COMMIT_ARGS[@]}"
        fi
    else
        echo "📝  git commit -m \"$MSG\" ${COMMIT_ARGS[*]}"
        if [ "$DRY_RUN" = "yes" ]
        then
            :
        else
            if ! git commit -m "$MSG" "${COMMIT_ARGS[@]}"
            then
                echo "❌ Commit failed (maybe no changes)."
                return 1
            fi
        fi
    fi

    # Push
    echo "🚀  git push $SET_UPSTREAM \"$FINAL_REMOTE\" \"$FINAL_BRANCH\""
    if [ "$DRY_RUN" = "yes" ]
    then
        return 0
    fi

    if ! git push $SET_UPSTREAM "$FINAL_REMOTE" "$FINAL_BRANCH"
    then
        echo "❌ Error while pushing."
        return 1
    fi

    echo "✅  Pushed to $FINAL_REMOTE/$FINAL_BRANCH."
}

# === Environment variables === 🌐
export EDITOR='nano'
export VISUAL='nano'
export PAGER='less'

# Settings for less
export LESS='-R --use-color -Dd+r$Du+b'
