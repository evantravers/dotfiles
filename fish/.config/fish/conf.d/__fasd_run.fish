function update_fasd_db --on-event fish_preexec -d "fasd takes record of the directories changed into"
    command fasd --proc (command fasd --sanitize "$argv") > "/dev/null" 2>&1
end
