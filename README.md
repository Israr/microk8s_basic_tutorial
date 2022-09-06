# Install micrk8s
```sh
    $ sudo snap install microk8s --classic
    $ sudo snap install helm --classic
    $ sudo usermod -a -G microk8s $USER
    $ sudo chown -f -R $USER ~/.kube
    # logout and login again.
    $ microk8s status --wait-ready
    microk8s is running
    high-availability: no
    datastore master nodes: 127.0.0.1:19001
    datastore standby nodes: none
    ...
    $ alias k=microk8s.kubectl
    $ k get no
    NAME            STATUS   ROLES    AGE     VERSION
    extp346360020   Ready    <none>   3h43m   v1.24.3-2+63243a96d1c393
    $ microk8s enable registry
    $ microk8s enable dns
    $ microk8s enable dashboard
    $ k enable dashbaord
    $ k enable ingress
```
# Create Hello World JS App and Dockerize 

Create a simple file index.js containing
```js
    var express = require('express');
    var app = express();
    app.get('/', function(req, res){
    res.send("Hello world!");
    });
```

```sh
    $ npm init
    $ npm i express
    $ node index.js
    # From another shell
    $ curl localhost:3000
    Hello world
```

Create a Dockerfile
```dockerfile
    FROM node:14-alpine
    WORKDIR /app/
    COPY index.js package.json /app/
    RUN npm install
    EXPOSE 3000
    CMD [ "node" , "index.js"]
```
Run Docker container
```sh
    $ docker build . -t hello
    $ docker run -d -p3000:3000 hello
    $ curl localhsot:3000
    Hello world!
    # push it to microk8s registry
    $ docker build . -t localhost:32000/hello
    $ docker push localhost:32000/hello

    # you can also save docker image from local repo to a file, and then import it to microk8s
    docker save hello > h.tar
    microk8s.ctr -n k8s.io image import h.tar
```

# Run in Kubernetes
```sh
    $ k run test --image=localhost:32000/hello --port=3000 
    pod/test created
    $ k get pods
    NAME   READY   STATUS    RESTARTS   AGE
    test   1/1     Running   0          5s
    $ k port-forward test 3000:3000
```

## Create A Deployment
 
Create a basic deployment using following deploy_0.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-deployment
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: localhost:32000/hello:latest
        ports:
        - containerPort: 3000
```
Test deployment

```sh
$ k apply -f deploy_0.yaml
$ k get pod
NAME                                READY   STATUS    RESTARTS   AGE
hello-deployment-5d8b6c4898-fhlbv   1/1     Running   0          22s
$ k port-forward hello-deployment-5d8b6c4898-fhlbv 2000:3000
Forwarding from 127.0.0.1:2000 -> 3000
Forwarding from [::1]:2000 -> 3000
$ curl localhost:2000
# Now expose deloyment
$ k get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-deployment   1/1     1            1           6m48s
$ k expose deployment hello-deployment --type=NodePort --name=hello-service
$ k get svc
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
hello-service   NodePort    10.152.183.19   <none>        3000:31745/TCP   110s
$ curl localhost:31745
Hello world!
```


# Enable Dashboard

```sh
# Get token
$ k create token default
```

Expose dashboard on a nodeport

```yaml
kind: Service
apiVersion: v1
metadata:
  name: k8s-dash-svc
  namespace: kube-system
spec:
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
  ports:
  - name: https
    nodePort: 30443
    port: 443
    targetPort: 443
    protocol: TCP
```

# Setting up Ingress

TBD