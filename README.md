# Learn Docker
This readme contains the notes I took while going through the [Boot.dev](https://www.boot.dev) course [Learn Docker](https://www.boot.dev/courses/learn-docker). The notes do not capture all of the course materia and are intended for my own review. 

## Getting Started
```
docker pull docker/getting-started
```
See image
```
docker images
```
## Run a Container
```
docker run -d -p hostport:containerport namespace/name:tag
```
```-d``` run in detached mode\
```-p``` Publish a container's port to the host\
```hostport``` The port on your local machine\
```containerport``` The port inside the container\
```namespace/name``` The name of the image (usually in the format username/repo)\
```tag``` The version of the image (often ```latest```)

Run the getting-started container
```
docker run -d -p 8965:80 docker/getting-started:latest
```
See running containers
```
docker ps
```
See running application, open browser at http://localhost:8965

## Stop a Container
```
docker stop container_id
```
## Mutliple Containers
```
docker run -d -p 8965:80 docker/getting-started
docker run -d -p 8966:80 docker/getting-started
docker run -d -p 8967:80 docker/getting-started
docker run -d -p 8968:80 docker/getting-started
docker run -d -p 8969:80 docker/getting-started
```
Open separate browser page for each port, see different apps

## Volumes
Create Volume
```
docker volume ghost-vol
```

See volumes
```
docker volume ls
```

Inspect volume on local machine
```
docker volume inspect ghost-vol
```

## Example: Ghost
Ghost is open source blogging software. Docker hosts an official image for Ghost on [Docker Hub](https://hub.docker.com/_/ghost)

Pull the Ghost image from Docker Hub
```
docker pull ghost
```
Run the ghost image in a new container
```
docker run -d -e NODE_ENV=development -e url=http://localhost:3001 -p 3001:2368 -v ghost-vol:/var/lib/ghost ghost
```
```-d``` runs the image in detached mode to avoid blocking the terminal\
```e NODE_ENV=development``` sets an environment variable within the container. This tells Ghost to run in 'development' mode (rather than 'production', for instance)\
```-e url=http://localhost:3001``` sets an environment variable telling Ghost that we want to be able to access it via a url on the host machine\
```-p 3001:2368``` port forwarding between container and host machine\
```-v ghost-vol:/var/lib/ghost``` mounts the ```ghost-vol``` created earlier to the ```/var/lib/ghost``` path in the container. Ghost will use the ```/var/lib/ghost``` directory to persist stateful data between runs.

Navigate to ```http://localhost:3001``` in the browser to see the new Ghost CMS.

## Exercise: Create a Ghost Website
Navigate to Ghost admin panel: ```http://localhost:3001/ghost/#/setup``` and create a new website:\
    - Title: My Docker Blog\
    - Name: _Your_ name\
    - Email: docker@test.com\
    - Password: correct horse

Create a new post and publish it.

View the new post at ```http://localhost:3001```

### Persist
Ensure volume is working by starting a new container and verifying the post is being served from the volume ghost-vol:

Get Container ID and then stop and remove the container
```
docker ps
docker stop CONTAINER_ID
docker rm CONTAINER_ID
```

Start a new container from the same image and the same volume
```
docker run -d -e NODE_ENV=development -e url=http://localhost:3001 -p 3001:2368 -v ghost-vol:/var/lib/ghost ghost
```

### Delete volume and container from machine
See all containers on machine, running or not
```
docker ps -a
```

Stop the ghost container
```
docker stop CONTAINER_ID
```

Remove the ghost container
```
docker rm CONTAINER_ID
```

Find the ghost volume
```
docker volume ls
```
Remove the ghost volume
```
docker volume rm ghost-vol
```

## Exec

Running commands inside a container.

Start a getting-started container
```
docker -d -p 8965:80 docker/getting-started
```

Run ```docker ps``` to get the container id (first 4 are good enough)\
Run the ```ls``` command from _inside the container_ using the ```exec``` command
```
docker exec CONTAINER_ID ls
```
Create a file hacker.log file inside the container
```
docker exec CONTAINER_ID touch hacker.log
```
Run ```docker exec CONTAINER_ID ls``` again to verify file created in container

### Exec netstat
Run the netstat program inside the container to see what software the container is using to serve its getting-started webpage
```
docker exec CONTAINER_ID netstat -ltnp
```

```
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1/nginx: master pro
tcp        0      0 :::80                   :::*                    LISTEN      1/nginx: master pro
```

### Live Shell
Run a shell session within the container
```
docker exec -it CONTAINER_ID /bin/sh
```
```i``` makes the ```exec``` command interactive\
```t``` provides a tty inteface\
```/bin/sh``` opens a shell session inside the container\
Change into the ```/usr/share/nginx/html``` directory\
```cd``` into tutorial directory\
change index.html, for example:
```
echo "I hacked you!" > index.html
```
Refresh page in browser

## Stop Network in Container
Start the container with ```--network none```
```
docker run -d --network none docker/getting-started
```

Connect with interactive shell
```
docker exec -it CONTAINER_ID /bin/sh
```

Ping google.com. Should hang for 2 seconds and then report an error message.

## Load Balancer
Download caddy image
```
docker pull caddy
```

Create an index1.html file in local project directory:
```
<html>
  <body>
    <h1>Hello from server 1</h1>
  </body>
</html>
```

Create an index2.html file in local project directory:
```
<html>
  <body>
    <h1>Hello from server 2</h1>
  </body>
</html>
```

Run a container for index1.html
```
docker run -d -p 8881:80 -v $PWD/index1.html:/usr/share/caddy/index.html caddy
```

Run a container for index2.html
```
docker run -d -p 8882:80 -v $PWD/index2.html:/usr/share/caddy/index.html caddy
```

In browser, go to both ```http://localhost:8881``` and ```http://localhost:8882```

### Create custom bridge network so containers can communicate while remaining separate

Create custom bridge network called "caddytest"
```
docker network create caddytest
```

Start and stop the caddy app servers, this time attaching them to the caddytest network. Do not use the -p flag to expose ports as we don't want these available from the host machine
```
docker run -d --network caddytest --name caddy1 -v $PWD/index1.html:/usr/share/caddy/index.html caddy 
```

```
docker run -d --network caddytest --name caddy2 -v $PWD/index2.html:/usr/share/caddy/index.html caddy 
```

Create another getting-started container and create a shell session within it
```
docker run -it --network caddytest docker/getting-started /bin/sh
```

From within getting-started shell, curl caddy1 and then caddy2.\
Docker has set up name resolution and the container names resolve resolve to the individual containers.

- Stop any containers that aren't the two caddy servers.
- Create a new file named Caddyfile in the local directory:
```
localhost:80

reverse_proxy caddy1:80 caddy2:80 {
	lb_policy       round_robin
}
```

Start the loadbalancer on port 8880:
```
docker run -d --network caddytest -p 8880:80 -v $PWD/Caddyfile:/etc/caddy/Caddyfile caddy
```

In browser, go to localhost://8880 and hit refresh. If browser is caching content, try curl:
```
curl http://localhost:8880
```

## Dockerfiles
Build images with dockerfiles.

Copy following into file named ```Dockerfile```
```
# This is a comment

# Use a lightweight debian os
# as the base image
FROM debian:stable-slim

# execute the 'echo "hello world"'
# command when the container runs
CMD ["echo", "hello world"]
```

Build a new image from the Dockerfile and call it helloworld
```
docker build . -t helloworld:latest
```
> [!NOTE]
> The `-t helloworld:test` flag tags the image with the name "helloworld" and the tag "latest". 
> Names are used to organize images and tags are used to organize versions

Run image in new container
```
docker run helloworld
```

Run `docker ps` and note that container no longer running. It ran the echo command to print "hello world" and then exited.

See the stopped container by running `docker ps -a`

Delete the Dockerfile

## Building a server
- Add the following Go code to a main.go file
```
package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	m := http.NewServeMux()

	m.HandleFunc("/", handlePage)

	const port = "8010"
	srv := http.Server{
		Handler:      m,
		Addr:         ":" + port,
		WriteTimeout: 30 * time.Second,
		ReadTimeout:  30 * time.Second,
	}

	// this blocks forever, until the server
	// has an unrecoverable error
	fmt.Println("server started on ", port)
	err := srv.ListenAndServe()
	log.Fatal(err)
}

func handlePage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")
	w.WriteHeader(200)
	const page = `<html>
<head></head>
<body>
	<p> Hello from Docker! I'm a Go server. </p>
</body>
</html>
`
	w.Write([]byte(page))
}
```
- Run `go mod init github.com/USERNAME/REPO` (be sure you've already created a repo for this project)
- Build the server: `go build`
- Run the server: `./DIRECTORY_NAME` (`go build` builds an executable with the directory name)
- Ensure you can connect to the server endpoint using the browser or with the `curl` command:
```
curl http://localhost:8010
```

Kill the server `ctrl + c`

## Dockerizing the server
The steps to create a docker image of the server are:
1. Build the server
2. Create a Dockerfile
3. Build an image using the Dockerfile (which will copy in the built server)
4. Run the image in a container

Create a Dockerfile at the root of the repository. We'll start with a simple, light-weight [Debian Linux OS](https://www.debian.org)
```
FROM debian:stable-slim
```
Add a [COPY](https://docs.docker.com/reference/dockerfile/#copy) command on the next line. For the simple case of copying a built Go program, we just need to copy the binary
```
# COPY Source Destination
COPY binary_name /bin/goserver
```
> [!NOTE]\
> The [ADD](https://docs.docker.com/reference/dockerfile/#add) command would work, but the additional functionality it provides is not needed for this exercise.
>

Add a CMD as the last line in the Dockerfile. This automatically starts the server process in the container when we start the container
```
CMD ["/bin/goserver"]
```

Build the image
```
docker build . -t goserver:latest
```

Start a new container from the image, being sure to forward the ports to local machine
```
docker run -p 8010:8010 goserver
```

> [!WARNING]
> If you get an `exec format error`, it's likely because you built the go server for your
> local architecture and trying to run in on linux. If this occurs, try rebuilding the
> image, and then rebuilding the Dockerfile, as shown below:

```
GOOS=linux GOARCH=amd64 go build
docker build . -t goserver:latest
docker run -p 8010:8010 goserver
```

run `curl` to ensure the server is running and you can connect to the container's webserver from your local machine
```
curl http://localhost:8010
```

## Creating an Environment
Create a more complex environment by making the port the server connects to configurable

Change the go code in main.go to get the port # from an environment variable (be sure to add "os" to the import list and remove the const value)
```
port := os.Getenv("PORT")
```

Change the port to 8999 by setting an environment variable in the shell
```
export PORT=8999
```

Rebuild the Go server and ensure it serves on port 8999
```
go build
./binary_name
curl http://localhost:8999
```

Add an ENV command to the Dockerfile before the CMD command
```
ENV PORT=8991
```

(If necessary), rebuild the go server for the linux architecture
```
GOOS=linux GOARCH=amd64 go build
```

Rebuild to Docker image
```
docker build . -t goserver:latest
```

Rerun the docker container, exposing the correct port
```
docker run -p 8991:8991 goserver
```

Verify you can curl to server `curl http://localhost:8991`

### Python Script

These image builds so far have been straight forward. Creating a server for Python, .NET, JavaScript, PHP, etc. requires installing supporting libraries. We'll create a Python server

- Copy the code below to a file named main.py\
- Copy the text of the [Frankenstein book](https://raw.githubusercontent.com/asweigart/codebreaker/master/frankenstein.txt) and save it to a file named `books/frankenstein.txt` off the project directory\
- Make sure you have Python 3.10+ installed
- Make sure the main.py code works on your local machine:
```
python3 main.py
```
It should print some stats about the characters in the frankenstein book.


```
def main():
    book_path = "books/frankenstein.txt"
    text = get_book_text(book_path)
    num_words = get_num_words(text)
    chars_dict = get_chars_dict(text)
    chars_sorted_list = chars_dict_to_sorted_list(chars_dict)

    print(f"--- Begin report of {book_path} ---")
    print(f"{num_words} words found in the document")
    print()

    for item in chars_sorted_list:
        if not item["char"].isalpha():
            continue
        print(f"The '{item['char']}' character was found {item['num']} times")

    print("--- End report ---")


def get_num_words(text):
    words = text.split()
    return len(words)


def sort_on(d):
    return d["num"]


def chars_dict_to_sorted_list(num_chars_dict):
    sorted_list = []
    for ch in num_chars_dict:
        sorted_list.append({"char": ch, "num": num_chars_dict[ch]})
    sorted_list.sort(reverse=True, key=sort_on)
    return sorted_list


def get_chars_dict(text):
    chars = {}
    for c in text:
        lowered = c.lower()
        if lowered in chars:
            chars[lowered] += 1
        else:
            chars[lowered] = 1
    return chars



def get_book_text(path):
    with open(path) as f:
        return f.read()


main()
```

Create a new Dockerfile named Dockerfile.py with the following contents:
```
FROM debian:stable-slim
COPY main.py main.py
COPY books/ books/
CMD ["python", "main.py"]
```

Build the image in the Dockerfile
```
docker build -t bookbot -f Dockerfile.py .
```

Run the image in a container
```
docker run bookbot
```

You should see an error because the Python interpreter was not installed on the image. Let's install it:
```
# Build from a slim Debian/Linux image
FROM debian:stable-slim

# Update apt
RUN apt update
RUN apt upgrade -y

# Install build tooling
RUN apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev

# Download Python interpreter code and unpack it
RUN wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz
RUN tar -xf Python-3.10.*.tgz

# Build the Python interpreter
RUN cd Python-3.10.8 && ./configure --enable-optimizations && make && make altinstall

# Copy our code into the image
COPY main.py main.py

# Copy our data dependencies
COPY books/ books/

# Run our Python script
CMD ["python3.10", "main.py"]
```

Rebuild the image
```
docker build -t bookbot -f Dockerfile.py .
```

Run the image in a new container
```
docker run bootbot
```
