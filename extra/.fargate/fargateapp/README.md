## Deploy

Test

```
kubectl port-forward service/service-logging 8080:80 -n fargate1
```

browse away localhost:8080 or:

```
curl localhost:8080
```

Look in CloudWatch logs:

CloudWatch > Log groups > fluent-bit-eks-fargate

```
2022-02-23T17:04:24.484+00:00

{
    "log":"2022-02-23T17:04:24.484397174Z stdout F 127.0.0.1 - - [23/Feb/2022:17:04:24 +0000] \"GET / HTTP/1.1\" 200 615 \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36\" \"81.96.210.11\""
}
```

etc. 

