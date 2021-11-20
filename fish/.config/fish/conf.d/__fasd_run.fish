function __fasd_expand_vars -d "Expands only the first occurance of a variable in the passed string without evaluating the string"
  set -lx vars (echo -n $argv | grep -oP '(?!\\\\)\$\K([A-z_][A-z0-9_]*?)([^A-z0-9_]|\b|\n)' | perl -pe 's/(.+?)(?:[^A-z0-9_]|\b)$/\1\n/' | sort -u)
  for var in $vars
    # Only replace if the variable is defined
    if set -q $var
      # Replacing the variable once is enough
      set argv (string replace -r '([^\\\\]|\b)\$'"$var" '$1'"$$var" "$argv") 
    end
  end
  # The following pipe does the same thing as fasd --sanitize
  printf '%s\\n' "$argv" | sed -e 's/\([^\]\)$( *[^ ]* *\([^)]*\)))*/\1\2/g' -e 's/\([^\]\)[|&;<>$`{}]\{1,\}/\1 /g' | tr -s " " \n
end

function __fasd_run -e fish_postexec -d "fasd records the directories changed into"
  set -lx RETVAL $status
  if test $RETVAL -eq 0 # if there was no error
    command fasd --proc (__fasd_expand_vars $argv) > "/dev/null" 2>&1 &
  end
end
