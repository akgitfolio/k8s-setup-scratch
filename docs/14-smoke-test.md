## Smoke Test

Ensure your Kubernetes cluster is functioning correctly.

### Data Encryption

Verify the ability to encrypt secret data at rest.

1. Create a generic secret:

   ```bash
   kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata"
   ```

2. Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

   ```bash
   sudo ETCDCTL_API=3 etcdctl get --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.crt --cert=/etc/etcd/etcd-server.crt --key=/etc/etcd/etcd-server.key /registry/secrets/default/kubernetes-the-hard-way | hexdump -C
   ```

3. Cleanup:
   ```bash
   kubectl delete secret kubernetes-the-hard-way
   ```

### Deployments

Verify the ability to create and manage deployments.

1. Create a deployment for the nginx web server:

   ```bash
   kubectl create deployment nginx --image=nginx:alpine
   ```

2. List the pod created by the nginx deployment:

   ```bash
   kubectl get pods -l app=nginx
   ```

   Expected output:

   ```
   NAME                    READY   STATUS    RESTARTS   AGE
   nginx-dbddb74b8-6lxg2   1/1     Running   0          10s
   ```

### Services

Verify the ability to access applications remotely using port forwarding.

1. Create a service to expose deployment nginx on node ports:

   ```bash
   kubectl expose deploy nginx --type=NodePort --port 80
   ```

2. Retrieve the node port:

   ```bash
   PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
   ```

3. Test to view the NGINX page:

   ```bash
   curl http://node01:$PORT_NUMBER
   curl http://node02:$PORT_NUMBER
   ```

   Expected output:

   ```
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   <body>
   ```

### Logs

Verify the ability to retrieve container logs.

1. Retrieve the full name of the nginx pod:

   ```bash
   POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
   ```

2. Print the nginx pod logs:

   ```bash
   kubectl logs $POD_NAME
   ```

   Expected output:

   ```
   10.32.0.1 - - [20/Mar/2019:10:08:30 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
   10.40.0.0 - - [20/Mar/2019:10:08:55 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
   ```

### Exec

Verify the ability to execute commands in a container.

1. Print the nginx version by executing the `nginx -v` command in the nginx container:

   ```bash
   kubectl exec -ti $POD_NAME -- nginx -v
   ```

   Expected output:

   ```
   nginx version: nginx/1.23.1
   ```

### Cleanup

Clean up test resources:

```bash
kubectl delete pod -n default busybox
kubectl delete service -n default nginx
kubectl delete deployment -n default nginx
```
