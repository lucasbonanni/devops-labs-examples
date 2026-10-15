.PHONY: up validate nodes down

up:
	docker compose up -d --wait
	cd demo-integral && terraform init && terraform apply -auto-approve
	kind export kubeconfig --name demo-eks-cluster

validate:
	bash demo-integral/scripts/validate.sh

nodes:
	kubectl get nodes -o wide
	kubectl get pods -A -o wide

down:
	cd demo-integral && terraform destroy -auto-approve
	docker compose down
