#!/usr/bin/env bash
set -e

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "== Nodos del cluster (kind actuando como 'cómputo' de EKS) =="
kubectl get nodes -o wide

echo "== Esperando deployments =="
kubectl rollout status deployment/demo-app --timeout=120s
kubectl rollout status deployment/nginx-demo --timeout=120s

echo "== Pods y nodo asignado =="
kubectl get pods -A -o wide

assert_spread_across_nodes() {
	local selector="$1"
	local node_count

	node_count=$(kubectl get pods -l "$selector" -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u | wc -l | tr -d '[:space:]')
	if [[ "$node_count" -lt 2 ]]; then
		echo "Se esperaba que '$selector' se ejecutara en al menos 2 nodos; encontrados: $node_count" >&2
		return 1
	fi
	echo "$selector está distribuido en $node_count nodos"
}

assert_spread_across_nodes "app=demo-app"
assert_spread_across_nodes "app=nginx"

echo "== Servicios =="
kubectl get svc -A

echo "== Probando demo-app (imagen local cargada en kind) =="
curl --fail --show-error --retry 10 --retry-connrefused --retry-delay 2 http://localhost:30080

echo
echo "== Probando Nginx =="
curl --fail --show-error --retry 10 --retry-connrefused --retry-delay 2 http://localhost:30081

echo
echo "== Probando Grafana =="
curl --fail --show-error --retry 10 --retry-connrefused --retry-delay 2 -o /dev/null http://localhost:30090/login
echo "Grafana responde en http://localhost:30090"

echo
echo "== Invocando la Lambda simulada en Moto =="
lambda_error=$(aws --cli-read-timeout 120 --cli-connect-timeout 5 --endpoint-url=http://localhost:5000 lambda invoke --function-name demo-lambda /tmp/lambda-out.json --query FunctionError --output text)
if [[ "$lambda_error" != "None" ]]; then
	echo "La Lambda terminó con error: $lambda_error" >&2
	cat /tmp/lambda-out.json >&2
	exit 1
fi
cat /tmp/lambda-out.json

echo
echo "== Describiendo el 'EKS' simulado en Moto =="
aws --endpoint-url=http://localhost:5000 eks describe-cluster --name demo-eks-cluster
