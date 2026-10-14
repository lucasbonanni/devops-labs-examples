docker compose up -d
terraform init
terraform plan
terraform apply -auto-approve
aws --endpoint-url=http://localhost:5000 s3 ls
terraform destroy -auto-approve
docker compose down
