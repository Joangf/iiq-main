check_docker() {
    docker -v &> /dev/null;
    return $?;
}

if check_docker; then
    echo "Docker is running"
    docker build -t iiq:1.0.0 .
    docker run -d -p 5000:5000 --name iiq iiq:1.0.0
else
    echo "Docker is not running"
fi
