# Demo integral DevOps local

La demo usa Moto Server para simular AWS (IAM, Lambda y EKS) y un clúster kind
local para ejecutar las cargas de Kubernetes. El EKS de Moto es solo una
simulación de la API; los pods corren en kind.

## Requisitos

- Docker Desktop iniciado
- Terraform 1.5 o superior, kind, kubectl y AWS CLI
- Make

## Ejecución

Desde la raíz del repositorio:

```sh
make up
make validate
```

Endpoints publicados en localhost:

- App: http://localhost:30080
- Nginx: http://localhost:30081
- Grafana (si `enable_monitoring = true`): http://localhost:30090
- Moto Server: http://localhost:5000

La Lambda se invoca contra Moto con AWS CLI; `make validate` prueba su invocación
y consulta el clúster EKS simulado. Para eliminar los recursos, ejecuta `make down`.
