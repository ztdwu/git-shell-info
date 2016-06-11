
function ssh_connection() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    echo "%{$fg_bold[magenta]%}(ssh) "
  fi
}

function print_stderr() { >&2 printf "$@"; }

function count_occurances() { echo "$raw" | grep -Ec "$@"; }

function git_prompt() {
    if [[ -z "$branch" ]]; then return; fi

    printf "${fg_bold[yellow]}($branch"
    if [[ -n "$upstream" ]]; then printf " ➜ $upstream"; fi
    printf ") "

    if [[ -n "$unmerged" && "$unmerged" != "0" ]]; then
        printf "${fg_bold[red]}[$unmerged MERGE CONFLICT ✘]"

    elif [[ -z "$ahead"      || "$ahead"     == "0" ]] &&
         [[ -z "$added"      || "$added"     == "0" ]] &&
         [[ -z "$modified"   || "$modified"  == "0" ]] &&
         [[ -z "$deleted"    || "$deleted"   == "0" ]] &&
         [[ -z "$typechange" || "$ahead"     == "0" ]] &&
         [[ -z "$untracked"  || "$untracked" == "0" ]]; then
        printf "${fg_bold[green]}[✔ clean]"

    else
        if [[ -n "$ahead"      && "$ahead"      != "0" ]]; then printf "${fg_bold[magenta]}(↑${ahead})";    fi
        if [[ -n "$behind"     && "$behind"     != "0" ]]; then printf "${fg_bold[magenta]}(↓${behind})";   fi
        if [[ -n "$added"      && "$added"      != "0" ]]; then printf "${fg_bold[green]}(+${added})";      fi
        if [[ -n "$modified"   && "$modified"   != "0" ]]; then printf "${fg_bold[green]}(μ${modified})";   fi
        if [[ -n "$deleted"    && "$deleted"    != "0" ]]; then printf "${fg_bold[red]}(-${deleted})";      fi
        if [[ -n "$typechange" && "$typechange" != "0" ]]; then printf "${fg_bold[cyan]}(τ${typechange})";  fi
        if [[ -n "$untracked"  && "$untracked"  != "0" ]]; then printf "${fg_bold[yellow]}(●${untracked})"; fi
    fi
}

function git_status() {
    declare -r raw="$(git status --porcelain 2>/dev/null)"
    if [[ -z "$raw" ]]; then return; fi

    unmerged=$(   count_occurances "^(AA|U.|.U) ")
    added=$(      count_occurances "^(A.|.A) ")
    modified=$(   count_occurances "^([MR].|.[MR]) ")
    deleted=$(    count_occurances "^(D.|.D) ")
    typechange=$( count_occurances "^(T.|.T) ")
    untracked=$(  count_occurances "^\?\? ")
}

function find_branch() {
    branch_info=$(git branch -vv 2>/dev/null | grep -E '^[*] ')
    branch_info="${branch_info:2}"

    ## initial commit
    if [[ -z "$branch_info" ]]; then
        branch=$(git status | grep "^On branch " | cut -d " " -f3)

    ## detached
    elif [[ "$branch_info" =~ '^\(HEAD detached at ([a-zA-Z0-9_\-]+)\)[ ]+[a-zA-Z0-9]+[ ]+.+$' ]]; then
        branch="detached HEAD ${match[1]}"

    ## diverged
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_\-]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/\-]+): ahead ([0-9]+), behind ([0-9]+)\].+$' ]]; then
        branch="${match[1]}"
        upstream="${match[2]}"
        ahead="${match[3]}"
        behind="${match[4]}"

    ## ahead
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_\-]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/\-]+): ahead ([0-9]+)\].+$' ]]; then
        branch="${match[1]}"
        upstream="${match[2]}"
        ahead="${match[3]}"

    ## behind
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_\-]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/\-]+): behind ([0-9]+)\].+$' ]]; then
        branch="${match[1]}"
        upstream="${match[2]}"
        behind="${match[4]}"

    ## has upstream, no ahead/behind
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_\-]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/\-]+)\].+$' ]]; then
        branch="${match[1]}"
        upstream="${match[2]}"

    ## no upstream
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_\-]+)[ ]+[a-zA-Z0-9]+[ ]+.+$' ]]; then
        branch="${match[1]}"

    else
        print_stderr "failed to get git repo status\n"; return 1
    fi
}

function repo-status() {
    git_status  2>/dev/null
    find_branch 2>/dev/null
    STATUS=$(git_prompt 2>/dev/null)
    if [[ -n "$STATUS" ]]; then
        echo " $STATUS"
    fi
}

local return_code="%(?..%{$fg_bold[red]%}[%?] )"
PROMPT=$'$(ssh_connection)%{$fg_bold[green]%}%n@%m%{$reset_color%}$(repo-status) $fg_bold[blue]%~\n%{$reset_color%}$fg_bold[blue]${return_code}λ%{$reset_color%} '
RPROMPT='[%D{%L:%M:%S %p}]'
