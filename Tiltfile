docker_compose("./docker-compose.yml")

docker_build('tilt.dev/oidc-client', '.',
    dockerfile='Dockerfile.dev',
    live_update = [
        sync('.', '/app'),
        run('esy x MorphOidcClient.exe'),
        fall_back_on('package.json'),
        restart_container()
    ]
)
