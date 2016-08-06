#!/bin/bash

shopt -s compat31

declare -r reset='\033[0m'
declare -r red='\033[1;31m'
declare -r green='\033[1;32m'
declare -r yellow='\033[1;33m'
declare -r cyan='\033[1;36m'
declare -r blue='\033[1;34m'
declare -r purple='\033[1;35m'
declare -r white='\033[1;37m'

function print_stderr() { >&2 printf "$@"; }

function terminate() { print_stderr "$@\n"; exit 1; }

function count_occurances() { echo "$raw" | grep -Ec "$@"; }

function git_prompt() {
    printf "${yellow}($branch"
    if [[ -n "$upstream" ]]; then printf " ➜ $upstream"; fi
    printf ") "

    if [[ -n "$unmerged" && "$unmerged" != "0" ]]; then
        printf "$red[$unmerged MERGE CONFLICT ✘]"

    elif [[ -z "$ahead"      || "$ahead"     == "0" ]] &&
         [[ -z "$added"      || "$added"     == "0" ]] &&
         [[ -z "$modified"   || "$modified"  == "0" ]] &&
         [[ -z "$deleted"    || "$deleted"   == "0" ]] &&
         [[ -z "$typechange" || "$ahead"     == "0" ]] &&
         [[ -z "$untracked"  || "$untracked" == "0" ]]; then
        printf "${green}[✔ clean]"

    else
        if [[ -n "$ahead"      && "$ahead"      != "0" ]]; then printf "${purple}(↑${ahead})";     fi
        if [[ -n "$behind"     && "$behind"     != "0" ]]; then printf "${purple}(↓${behind})";    fi
        if [[ -n "$added"      && "$added"      != "0" ]]; then printf "${green}(+${added})";      fi
        if [[ -n "$modified"   && "$modified"   != "0" ]]; then printf "${green}(μ${modified})";   fi
        if [[ -n "$deleted"    && "$deleted"    != "0" ]]; then printf "${red}(-${deleted})";      fi
        if [[ -n "$typechange" && "$typechange" != "0" ]]; then printf "${cyan}(τ${typechange})";  fi
        if [[ -n "$untracked"  && "$untracked"  != "0" ]]; then printf "${yellow}(●${untracked})"; fi
    fi

    if [[ -n "$GIT_SHELL_SHOW_STASHES" || -n "$GIT_SHELL_SHOW_STASHES_VERBOSE" ]]; then
        stashes=$(git stash list 2>/dev/null | wc -l)
        if [[ -n "$stashes" && "$stashes" != "0" ]]; then
            printf " ${white}(${stashes}";
            if [[ -n "$GIT_SHELL_SHOW_STASHES_VERBOSE" ]]; then
                printf " stashed"
            fi
            printf ")"
        fi
    fi

    printf "${reset}"
}

function git_status() {
    declare -r raw=$(git status --porcelain 2>/dev/null)
    if [[ -z "$raw" ]]; then return; fi

    unmerged=$(   count_occurances "^(AA|U.|.U) ")
    added=$(      count_occurances "^(A.|.A) ")
    modified=$(   count_occurances "^([MR].|.[MR]) ")
    deleted=$(    count_occurances "^(D.|.D) ")
    typechange=$( count_occurances "^(T.|.T) ")
    untracked=$(  count_occurances "^\?\? ")
}

function find_branch() {
    local branch_info=$(git branch -vv 2>/dev/null | grep -E '^[*] ')
    local branch_info="${branch_info:2}"

    ## initial commit
    if [[ -z "$branch_info" ]]; then
        branch=$(git status | grep "^On branch " | cut -d " " -f3)

    ## detached
    elif [[ "$branch_info" =~ '^\((HEAD detached at [a-zA-Z0-9_\-\/]+)\)[ ]+[a-zA-Z0-9]+[ ]+.+$' ]]; then
        branch="${BASH_REMATCH[1]}"

    ## diverged
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/]+): ahead ([0-9]+), behind ([0-9]+)\].+$' ]]; then
        branch="${BASH_REMATCH[1]}"
        upstream="${BASH_REMATCH[2]}"
        ahead="${BASH_REMATCH[3]}"
        behind="${BASH_REMATCH[4]}"

    ## ahead
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/]+): ahead ([0-9]+)\].+$' ]]; then
        branch="${BASH_REMATCH[1]}"
        upstream="${BASH_REMATCH[2]}"
        ahead="${BASH_REMATCH[3]}"

    ## behind
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/]+): behind ([0-9]+)\].+$' ]]; then
        branch="${BASH_REMATCH[1]}"
        upstream="${BASH_REMATCH[2]}"
        behind="${BASH_REMATCH[4]}"

    ## has upstream, no ahead/behind
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_]+)[ ]+[a-zA-Z0-9]+[ ]+\[([0-9A-Za-z_/]+)\].+$' ]]; then
        branch="${BASH_REMATCH[1]}"
        upstream="${BASH_REMATCH[2]}"

    ## no upstream
    elif [[ "$branch_info" =~ '^([a-zA-Z0-9_]+)[ ]+[a-zA-Z0-9]+[ ]+.+$' ]]; then
        branch="${BASH_REMATCH[1]}"

    else
        print_stderr "failed to get git repo status\n"; return 1
    fi
}

function main() {
    git_status
    find_branch
    git_prompt
}
main