/*
======================================
NAMESPACES
======================================
*/

// Namespaces
resource "kubernetes_namespace" "business" {
  metadata {
    name   = "business-app"
  }
}
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name   = "monitoring-app"
  }
}
resource "kubernetes_namespace" "aws_ns" {
  metadata {
    name = "aws-app"
  }
}

/*
======================================
monitoring_ns resources
======================================
*/
resource "kubernetes_deployment" "tomcat_monitoring" {
  metadata {
    name    = "tomcat-monitoring-depl"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels  = {
      app = "monitoring-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "monitoring-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "monitoring-app"
        }
      }

      spec {
        container {
          name    = "tomcat"
          image   = "${local.tomcat_repo_url}:9.0"
        }
      }
    }
  }
}
/*
======================================
aws_ns resources
======================================
*/
resource "kubernetes_secret" "application_deployment_user_secret" {
  metadata {
    name      = "application-deployment-credentials"
    namespace = kubernetes_namespace.aws_ns.metadata[0].name
  }

  data = {
    username    = aws_iam_access_key.ApplicationDeployment_user_key.id
    password    = aws_iam_access_key.ApplicationDeployment_user_key.secret
    description = "This secret is used to deploy application through a Lambda"
  }
}
resource "kubernetes_daemonset" "application_deployment_app" {
  metadata {
    name    = "application-deployment-ds"
    namespace = kubernetes_namespace.aws_ns.metadata[0].name
    labels  = {
      app = "deployment-app"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "deployment-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "deployment-app"
        }
      }

      spec {
        container {
          name    = "core"
          image   = local.debian_repo_url
          command = [ "/bin/sh", "-c", "--" ]
          args    = [ "apt-get update; apt-get install -y curl ca-certificates jq; curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"; install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; while true; do sleep 30; done;" ]

          # mounth the secret as a file
          volume_mount {
            name       = "deployment-secret"
            mount_path = "/secret/deployment-secret.txt"
            read_only  = true
          }
        }

        service_account_name = kubernetes_service_account.deployment_app.metadata[0].name

        volume {
          name   = "deployment-secret"
          secret {
            secret_name = kubernetes_secret.application_deployment_user_secret.metadata[0].name
          }
        }
      }
    }
  }
}
resource "kubernetes_service_account" "deployment_app" {
  metadata {
    name      = "deployment-app"
    namespace = kubernetes_namespace.aws_ns.metadata[0].name
  }
}
