## Developing the image
### Building and running
```bash
# Clone the project from Github
git clone https://github.com/0001ca/docker-stockapp.git
cd docker-stockapp

# Build the images
docker build --build-arg PHP_VERSION=8.1 -t=0001ca/stockapp:latest -f Dockerfile .
docker build --build-arg PHP_VERSION=8.0 -t=0001ca/stockapp:latest-php8 -f Dockerfile .
docker build --build-arg PHP_VERSION=7.4 -t=0001ca/stockapp:latest-php7 -f Dockerfile .

#Run the image as a container adding app data folder and persistant mysql
docker run -i -t -p "80:80" -v ${PWD}/app:/app -p 3306:3306 -v ${PWD}/mysql:/var/lib/mysql 0001ca/stockapp:latest

```



