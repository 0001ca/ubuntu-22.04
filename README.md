### Clone the Docker Container
```bash
# Clone the project from Github
git clone https://github.com/0001ca/ubuntu-22.04.git
cd docker-stockapp
```
# Build the image
```bash
docker build --build-arg PHP_VERSION=8.1 -t=0001ca/ubuntu-22.04:latest -f Dockerfile .
```

### Run the image
```bash
#Run the image as a container adding app data folder and persistant mysql
docker run -i -t -p "80:80" -v ${PWD}/app:/app -p 3306:3306 -v ${PWD}/mysql:/var/lib/mysql 0001ca/ubuntu-22.04:latest
```





