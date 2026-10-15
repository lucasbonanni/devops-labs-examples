.PHONY: up validate down

up:
	docker compose up -d --wait
	cd demo-integral && terraform init && terraform apply -auto-approve
	kind export kubeconfig --name demo-eks-cluster

validate:
	bash demo-integral/scripts/validate.sh

down:
	cd demo-integral && terraform destroy -auto-approve
	docker compose down
