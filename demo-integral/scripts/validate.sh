#!/usr/bin/env bash
set -e

echo "== Nodos del cluster (kind actuando como 'cómputo' de EKS) =="
kubectl get nodes -o wide

echo "== Pods =="
kubectl get pods -A

echo "== Servicios =="
kubectl get svc

echo "== Probando demo-app (imagen local cargada en kind) =="
curl -s http://localhost:30080

echo
echo "== Invocando la Lambda simulada en Moto =="
aws --endpoint-url=http://localhost:5000 lambda invoke --function-name demo-lambda /tmp/lambda-out.json
cat /tmp/lambda-out.json

echo
echo "== Describiendo el 'EKS' simulado en Moto =="
aws --endpoint-url=http://localhost:5000 eks describe-cluster --name demo-eks-cluster
