function __icsuper_usage
    printf '%s\n' \
        'Usage: icsuper <command>' \
        '' \
        'Commands:' \
        '  start    Start all four development services' \
        '  stop     Stop the managed tmux session' \
        '  restart  Restart all four development services' \
        '  status   Show service and tmux window status' \
        '  attach   Attach to the managed tmux session' \
        '  help     Show this help'
end

function __icsuper_error
    echo "icsuper: $argv" >&2
end

function __icsuper_session_exists --argument-names session_name
    command tmux has-session -t "=$session_name" 2>/dev/null
end

function __icsuper_http_up --argument-names url
    set -l response (command curl --fail --silent --max-time 2 $url 2>/dev/null)
    or return 1

    string match --quiet -- '*"status":"UP"*' "$response"
end

function __icsuper_web_up --argument-names url
    command curl --fail --silent --output /dev/null --max-time 2 $url 2>/dev/null
end

function __icsuper_shell_command --argument-names command_text
    printf 'fish -lc %s' (string escape -- $command_text)
end

function __icsuper_prepare_window --argument-names session_name window_name working_directory command_text
    set -l target "$session_name:$window_name"

    command tmux set-option -w -t $target remain-on-exit on >/dev/null
    or return 1

    set -l shell_command (__icsuper_shell_command "$command_text")
    command tmux respawn-pane -k -t $target "$shell_command"
end

function __icsuper_start
    set -l repositories_dir $HOME/repositories
    set -q ICSUPER_REPOSITORIES_DIR; and set repositories_dir $ICSUPER_REPOSITORIES_DIR

    set -l session_name icsuper
    set -q ICSUPER_TMUX_SESSION; and set session_name $ICSUPER_TMUX_SESSION

    set -l keychain_service icsuper-local-ai
    set -l admin_dir $repositories_dir/icsuper-admin
    set -l web_dir $repositories_dir/icsuper-web
    set -l xcx_dir $repositories_dir/icsuper-xcx
    set -l superman_jar $admin_dir/superman-api/target/superman-api-1.0.0.jar
    set -l admin_jar $admin_dir/ruoyi-admin/target/ruoyi-admin.jar

    if __icsuper_session_exists $session_name
        echo "ICsuper is already running in tmux session '$session_name'."
        echo "Run 'icsuper attach' to view it."
        return 0
    end

    for dependency in tmux security java pnpm curl lsof fish
        if not command -q $dependency
            __icsuper_error "missing dependency: $dependency"
            return 1
        end
    end

    for directory in $admin_dir $web_dir $xcx_dir
        if not test -d $directory
            __icsuper_error "missing project directory: $directory"
            return 1
        end
    end

    for artifact in $superman_jar $admin_jar
        if not test -f $artifact
            __icsuper_error "missing build artifact: $artifact"
            __icsuper_error "build the corresponding Maven module before starting"
            return 1
        end
    end

    for account in AI_ADP_UNIFIED_APP_KEY AI_TOOL_API_KEY AI_TOOL_AUTH_SECRET
        if not command security find-generic-password -s $keychain_service -a $account >/dev/null 2>&1
            __icsuper_error "missing Keychain item '$account' in service '$keychain_service'"
            return 1
        end
    end

    for port in 9088 6139 5666
        if command lsof -nP "-iTCP:$port" -sTCP:LISTEN >/dev/null 2>&1
            __icsuper_error "port $port is already in use; stop the existing service first"
            return 1
        end
    end

    set -l superman_command (string join '; ' \
        "set -lx AI_ADP_UNIFIED_APP_KEY (security find-generic-password -s $keychain_service -a AI_ADP_UNIFIED_APP_KEY -w); or exit 1" \
        "set -lx AI_TOOL_API_KEY (security find-generic-password -s $keychain_service -a AI_TOOL_API_KEY -w); or exit 1" \
        "set -lx AI_TOOL_AUTH_SECRET (security find-generic-password -s $keychain_service -a AI_TOOL_AUTH_SECRET -w); or exit 1" \
        "exec java -jar superman-api/target/superman-api-1.0.0.jar --spring.profiles.active=test")
    set -l admin_command 'exec java -jar ruoyi-admin/target/ruoyi-admin.jar --spring.profiles.active=test'
    set -l web_command 'exec pnpm dev:antd'
    set -l xcx_command 'set -lx VITE_API_URL_TEST http://127.0.0.1:9088; exec pnpm exec uni -p mp-weixin'

    command tmux new-session -d -s $session_name -n superman-api -c $admin_dir
    or begin
        __icsuper_error "unable to create tmux session '$session_name'"
        return 1
    end

    if not __icsuper_prepare_window $session_name superman-api $admin_dir "$superman_command"
        command tmux kill-session -t "=$session_name" 2>/dev/null
        __icsuper_error 'unable to start the superman-api window'
        return 1
    end

    command tmux new-window -d -t "=$session_name" -n ruoyi-admin -c $admin_dir
    and __icsuper_prepare_window $session_name ruoyi-admin $admin_dir "$admin_command"
    or begin
        command tmux kill-session -t "=$session_name" 2>/dev/null
        __icsuper_error 'unable to start the ruoyi-admin window'
        return 1
    end

    echo 'Starting Java backends...'
    set -l backends_ready 0
    for attempt in (seq 1 90)
        if __icsuper_http_up http://127.0.0.1:9088/api/actuator/health
            and __icsuper_http_up http://127.0.0.1:6139/actuator/health
            set backends_ready 1
            break
        end
        sleep 1
    end

    if test $backends_ready -ne 1
        __icsuper_error 'Java backends did not become healthy within 90 seconds'
        __icsuper_error "the tmux session was kept for diagnosis; run 'icsuper attach'"
        return 1
    end

    command tmux new-window -d -t "=$session_name" -n icsuper-web -c $web_dir
    and __icsuper_prepare_window $session_name icsuper-web $web_dir "$web_command"
    or begin
        __icsuper_error 'unable to start the icsuper-web window'
        return 1
    end

    command tmux new-window -d -t "=$session_name" -n icsuper-xcx -c $xcx_dir
    and __icsuper_prepare_window $session_name icsuper-xcx $xcx_dir "$xcx_command"
    or begin
        __icsuper_error 'unable to start the icsuper-xcx window'
        return 1
    end

    command tmux select-window -t "$session_name:superman-api"

    echo "ICsuper started in tmux session '$session_name'."
    echo '  superman-api  http://127.0.0.1:9088'
    echo '  ruoyi-admin   http://127.0.0.1:6139'
    echo '  icsuper-web   http://127.0.0.1:5666'
    echo '  icsuper-xcx   dist/dev/mp-weixin'
    echo "Run 'icsuper attach' to view all four windows."
end

function __icsuper_stop
    set -l session_name icsuper
    set -q ICSUPER_TMUX_SESSION; and set session_name $ICSUPER_TMUX_SESSION

    if not __icsuper_session_exists $session_name
        echo "ICsuper tmux session '$session_name' is already stopped."
        return 0
    end

    command tmux kill-session -t "=$session_name"
    or begin
        __icsuper_error "unable to stop tmux session '$session_name'"
        return 1
    end

    echo "ICsuper tmux session '$session_name' stopped."
end

function __icsuper_status
    set -l session_name icsuper
    set -q ICSUPER_TMUX_SESSION; and set session_name $ICSUPER_TMUX_SESSION

    if not __icsuper_session_exists $session_name
        echo "ICsuper tmux session '$session_name' is stopped."
        return 1
    end

    echo "Tmux session: $session_name"
    command tmux list-windows -t "=$session_name" -F '  #{window_name}: #{?pane_dead,exited,running}'

    if __icsuper_http_up http://127.0.0.1:9088/api/actuator/health
        echo '  superman-api health: UP'
    else
        echo '  superman-api health: DOWN'
    end

    if __icsuper_http_up http://127.0.0.1:6139/actuator/health
        echo '  ruoyi-admin health: UP'
    else
        echo '  ruoyi-admin health: DOWN'
    end

    if __icsuper_web_up http://127.0.0.1:5666
        echo '  icsuper-web HTTP: UP'
    else
        echo '  icsuper-web HTTP: DOWN'
    end
end

function __icsuper_attach
    set -l session_name icsuper
    set -q ICSUPER_TMUX_SESSION; and set session_name $ICSUPER_TMUX_SESSION

    if not __icsuper_session_exists $session_name
        __icsuper_error "tmux session '$session_name' is not running"
        return 1
    end

    if set -q TMUX
        command tmux switch-client -t "=$session_name"
    else
        command tmux attach-session -t "=$session_name"
    end
end

function icsuper --description 'Manage ICsuper local development services in tmux'
    set -l subcommand $argv[1]
    test -n "$subcommand"; or set subcommand help

    switch $subcommand
        case help -h --help
            __icsuper_usage
        case start
            __icsuper_start
        case stop
            __icsuper_stop
        case restart
            __icsuper_stop
            or return $status
            __icsuper_start
        case status
            __icsuper_status
        case attach
            __icsuper_attach
        case '*'
            echo "icsuper: unknown command '$subcommand'" >&2
            __icsuper_usage >&2
            return 2
    end
end
