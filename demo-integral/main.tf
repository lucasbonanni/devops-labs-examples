# ---------------------------------------------------------------------------
# 1. "EKS" simulado en Moto — enseña la sintaxis real de AWS sin costo
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eks_role" {
  name = "demo-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_eks_cluster" "demo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"] # dummy, Moto no valida la red real
  }
}

# ---------------------------------------------------------------------------
# 2. Lambda simulada en Moto (se puede invocar de verdad y responde)
# ---------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "demo-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_lambda_function" "demo" {
  function_name    = "demo-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# ---------------------------------------------------------------------------
# 3. Imagen Docker local -> build + load directo al cluster kind
# ---------------------------------------------------------------------------
resource "null_resource" "build_and_load_image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "docker build -t ${var.app_image_name} ${path.module}/app && kind load docker-image ${var.app_image_name} --name ${kind_cluster.demo_eks.name}"
  }

  depends_on = [kind_cluster.demo_eks]
}

resource "kubernetes_deployment_v1" "demo_app" {
  metadata {
    name   = "demo-app"
    labels = { app = "demo-app" }
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "demo-app" } }

    template {
      metadata { labels = { app = "demo-app" } }
      spec {
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"

          label_selector {
            match_labels = { app = "demo-app" }
          }
        }

        container {
          name              = "demo-app"
          image             = var.app_image_name
          image_pull_policy = "IfNotPresent"
          port { container_port = 8080 }
        }
      }
    }
  }

  depends_on = [null_resource.build_and_load_image]
}

resource "kubernetes_service_v1" "demo_app" {
  metadata { name = "demo-app" }

  spec {
    selector = { app = "demo-app" }
    port {
      port        = 80
      target_port = 8080
      node_port   = 30080
    }
    type = "NodePort"
  }
}

# ---------------------------------------------------------------------------
# 4. Nginx de ejemplo (tu recurso original)
# ---------------------------------------------------------------------------
resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name   = "nginx-demo"
    labels = { app = "nginx" }
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "nginx" } }

    template {
      metadata { labels = { app = "nginx" } }
      spec {
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"

          label_selector {
            match_labels = { app = "nginx" }
          }
        }

        container {
          image = "nginx:alpine"
          name  = "nginx"
          port { container_port = 80 }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata { name = "nginx-demo" }

  spec {
    selector = { app = "nginx" }
    port {
      port        = 80
      target_port = 80
      node_port   = 30081
    }
    type = "NodePort"
  }
}

# ---------------------------------------------------------------------------
# 5. Monitoreo opcional con kube-prometheus-stack
# ---------------------------------------------------------------------------
resource "helm_release" "monitoring" {
  count            = var.enable_monitoring ? 1 : 0
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600
  values           = [file("${path.module}/monitoring/values-prometheus.yaml")]
}
