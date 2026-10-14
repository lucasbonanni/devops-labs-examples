output "kubeconfig_command" {
  value = "kind export kubeconfig --name ${kind_cluster.demo_eks.name}"
}

output "demo_app_url" {
  value = "http://localhost:30080"
}

output "lambda_invoke_command" {
  value = "aws --endpoint-url=http://localhost:5000 lambda invoke --function-name demo-lambda /tmp/out.json && cat /tmp/out.json"
}

output "eks_describe_command" {
  value = "aws --endpoint-url=http://localhost:5000 eks describe-cluster --name ${var.cluster_name}"
}
