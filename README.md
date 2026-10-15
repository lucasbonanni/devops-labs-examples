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
make nodes
```

Endpoints publicados en localhost:

- App: http://localhost:30080
- Nginx: http://localhost:30081
- Grafana: http://localhost:30090 (usuario y contraseña: `admin`)
- Moto Server: http://localhost:5000

La Lambda se invoca contra Moto con AWS CLI; `make validate` prueba su invocación
y consulta el clúster EKS simulado. `make nodes` muestra los nodos de kind y el
nodo asignado a cada pod; `make validate` comprueba que las réplicas de la app y
Nginx estén repartidas en al menos dos nodos. Para eliminar los recursos,
ejecuta `make down`.
