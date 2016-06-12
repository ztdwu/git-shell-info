# git-shell-info

**`git-shell-info`** is a theme for [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) that displays your Git repo's current status in the shell.

## Example:

In the beginning we're on branch **`alpha`** with a clean working directory. Notice that after setting an upstream, the prompt now displays **`(↑1)`**. This means the local branch is 1 commit ahead of its upstream.

![Example1](/images/1.png?raw=true)

---

The prompt will update accordingly for every untracked files created, or any tracked files that is added, deleted, or modified. Here, we ended up with 2 newly added files and 1 deleted file, which being 1 commit ahead of the upstream.
![Example2](/images/2.png?raw=true)

---

Now the repo is 2 commits head. After pushing the changes, the repo status is reset to **`clean`**.
![Example3](/images/3.png?raw=true)

---

Any merge conflicts will be displayed in a big red warning, and won't go away until it's fixed.
![Example4](/images/4.png?raw=true)

---

## Installation:
For **`oh-my-zsh`** users, simply copy **`git-shell-info.zsh-theme`** to **`~/.oh-my-zsh/themes/`** and add **`ZSH_THEME="git-shell-info"`** to **`~/.zshrc`**.

For non **`oh-my-zsh`** users, there is also a **`git-shell-info.sh`** script that does basically the same thing, but you'll have to manually embed it into the prompt definition of your shell's configuration. For example, in **`bash`**, open **`~/.bashrc`** and find the line **`PS1=...`**, then place a call to **`$(git-shell-info.sh)`** somewhere inside the definition.

## Note:
By default, the number of stashes is hidden from prompt display. To enable this feature, export one of the variables `GIT_SHELL_SHOW_STASHES_VERBOSE=1` or `GIT_SHELL_SHOW_STASHES=1` (for example export it in **`.zshrc`**) to show the stash count.
