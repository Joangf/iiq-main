check_docker() {
    docker -v &> /dev/null;
    return $?;
}

if check_docker; then
    echo "Docker is running"
    docker stop iiq
    docker rm iiq
    docker rmi iiq:1.0.0
else
    echo "Docker is not running"
fi