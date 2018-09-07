# TL;DR

Ambassador is an envoy-proxy based reverse-proxy for Kubernetes that provides a nice way to dynamically configure service routes as services are added and removed via annotations on each service.  

## Details

https://www.getambassador.io/
Ambassador integrates Envoy with Kubernetes using custom annotations - ex:

```
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind:  Mapping
      name:  httpbin_mapping
      prefix: /httpbin/
      service: httpbin.org:80
      host_rewrite: httpbin.org
spec:
  ports:
  - name: httpbin
    port: 80
```

* https://www.getambassador.io/user-guide/getting-started
* https://www.getambassador.io/reference/mappings
* https://www.envoyproxy.io/docs/envoy/latest/intro/comparison
* Ambassador is istio friendly:
    - https://www.getambassador.io/user-guide/with-istio
    - https://istio.io/docs/tasks/traffic-management/ingress/
* We would replace the auth handling for jupyterhub, CSRF, and cookie-to-head auth transfer that we currently implement in nginx with an envoy filter that calls out to an auth service that we write:
    - https://www.envoyproxy.io/docs/envoy/latest/api-v2/config/filter/http/ext_authz/v2alpha/ext_authz.proto#config-filter-http-ext-authz-v2alpha-httpservice
    - https://github.com/uc-cdis/cloud-automation/blob/master/kube/services/revproxy/00nginx-config.yaml
    - https://nginx.org/en/docs/http/ngx_http_auth_request_module.html

## Diagnostics

https://www.getambassador.io/reference/diagnostics

On the adminvm:
```
  kubectl port-forward ambassador-xxxx-yyy 8877
```

From your laptop:
```
LOGINNAME=yourLogin
ssh -L 127.0.0.1:8877:localhost:8877 ${LOGINNAME}@cdistest.csoc
```

## Auth Service

https://www.getambassador.io/reference/services/auth-service
