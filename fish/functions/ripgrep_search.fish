function ripgrep_search
  set -l RG_PREFIX 'rg --column --line-number --no-heading --color=always --smart-case'

  set -l result (
    FZF_DEFAULT_COMMAND="$RG_PREFIX ''" fzf \
      --ansi \
      --disabled \
      --bind "change:reload:$RG_PREFIX {q} || true" \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'right:60%:+{2}+3/3' \
      --delimiter ':'
  )

  if test -n "$result"
    commandline -t (echo $result | cut -d: -f1)
  end
  commandline -f repaint
end
