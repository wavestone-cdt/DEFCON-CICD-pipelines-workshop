// Restricted PSP policy is partly based on https://github.com/IronCore864/ekspsp
/*
======================================
PSP
======================================
*/
// Restricted PSP (still allow default caps + root to ease the lab)
resource "kubernetes_pod_security_policy" "restricted" {
  metadata {
    name        = "restricted"
    annotations = {
      # docker/default identifies a profile for seccomp, but it is not particularly tied to the Docker runtime
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "docker/default,runtime/default"
      "seccomp.security.alpha.kubernetes.io/defaultProfileName"  = "runtime/default"
    }
  }
  spec {
    privileged = false
    # Required to prevent escalations to root.
    allow_privilege_escalation = false
    # Allow core volume types.
    volumes = [
      "configMap",
      "emptyDir",
      "projected",
      "secret",
      "downwardAPI",
      # Assume that ephemeral CSI drivers & persistentVolumes set up by the cluster admin are safe to use.
      "csi",
      "persistentVolumeClaim",
      "ephemeral",
    ]
    host_network = false
    host_ipc = false
    host_pid = false
    run_as_user {
      rule = "RunAsAny"
    }
    se_linux {
      rule = "RunAsAny"
    }
    supplemental_groups {
      rule = "RunAsAny"
    }
    fs_group {
      rule = "RunAsAny"
    }
    read_only_root_filesystem = false
  }
}

// Create per PSP clusterrole
resource "kubernetes_cluster_role" "psp_restricted" {
  metadata {
    name = "psp-restricted"
  }

  rule {
    api_groups    = ["policy"]
    resources     = ["podsecuritypolicies"]
    verbs         = ["use"]
    resource_names = [kubernetes_pod_security_policy.restricted.metadata[0].name]
  }
}
resource "kubernetes_cluster_role" "psp_privileged" {
  metadata {
    name = "psp-privileged"
  }

  rule {
    api_groups    = ["policy"]
    resources     = ["podsecuritypolicies"]
    verbs         = ["use"]
    resource_names = ["eks.privileged"]
  }
}

/*
======================================
Roles & RoleBinding
======================================
*/
// admin roles for jenkins, monitoring & deployment_app_sa
resource "kubernetes_role_binding" "jenkins_business_app" {
  metadata {
    name      = "jenkins-business-app-rb"
    namespace = kubernetes_namespace.business.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = aws_iam_user.jenkins.name
  }
}
resource "kubernetes_role_binding" "monitoring_app" {
  metadata {
    name      = "monitoring-app-rb"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "User"
    name      = aws_iam_user.k8s_monitoring.name
    api_group = "rbac.authorization.k8s.io"
  }
}
resource "kubernetes_role_binding" "deployment_app_sa" {
  metadata {
    name      = "deployment-app-sa"
    namespace = kubernetes_namespace.aws_ns.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.deployment_app.metadata[0].name
    namespace = kubernetes_namespace.aws_ns.metadata[0].name
  }
}

// Allow any authenticated user to list namespaces
resource "kubernetes_cluster_role" "allow_ns_listing" {
  metadata {
    name = "allow-ns-listing"
  }

  rule {
    api_groups    = [""]
    resources     = ["namespaces"]
    verbs         = ["list", "get"]
  }
}
resource "kubernetes_cluster_role_binding" "allow_ns_listing_authenticated" {
  metadata {
    name      = "allow-ns-listing-authenticated"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.allow_ns_listing.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:authenticated"
  }
}
// Allow any authenticated user to list RBAC
resource "kubernetes_cluster_role" "allow_rbac_listing" {
  metadata {
    name = "allow-rbac-listing"
  }

  rule {
    api_groups    = ["rbac.authorization.k8s.io"]
    resources     = [
      "clusterroles",
      "clusterrolebindings",
      "roles",
      "rolebindings",
    ]
    verbs         = ["list", "get"]
  }
}
resource "kubernetes_cluster_role_binding" "allow_rbac_listing_authenticated" {
  metadata {
    name      = "allow-rbac-listing-authenticated"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.allow_rbac_listing.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:authenticated"
  }
}
// Allow any authenticated user to list PSP
resource "kubernetes_cluster_role" "allow_psp_listing" {
  metadata {
    name = "allow-psp-listing"
  }

  rule {
    api_groups    = ["policy"]
    resources     = ["podsecuritypolicies"]
    verbs         = ["list", "get"]
  }
}
resource "kubernetes_cluster_role_binding" "allow_psp_listing_authenticated" {
  metadata {
    name      = "allow-psp-listing-authenticated"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.allow_psp_listing.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:authenticated"
  }
}

// PSP role bindings
// Make default authenticated users being restricted
resource "kubernetes_cluster_role_binding" "default_psp_binding" {
  metadata {
    name      = "default-psp-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.psp_restricted.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:authenticated"
  }

  # Ensure other PSP are created first
  depends_on = [
    kubernetes_cluster_role_binding.psp_restricted_namespaces,
    kubernetes_cluster_role_binding.psp_privileged_namespaces,
    #kubernetes_role_binding.awsnode_psp_binding,
    #kubernetes_role_binding.coredns_psp_binding,
    #kubernetes_role_binding.kubeproxy_psp_binding,
  ]
}

// apply PSP at namespace level
resource "kubernetes_cluster_role_binding" "psp_restricted_namespaces" {
  metadata {
    name      = "psp-restricted-namespaces"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.psp_restricted.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:serviceaccounts:${kubernetes_namespace.business.metadata[0].name}"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:serviceaccounts:${kubernetes_namespace.aws_ns.metadata[0].name}"
  }
}
resource "kubernetes_cluster_role_binding" "psp_privileged_namespaces" {
  metadata {
    name      = "psp-privileged-namespaces"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.psp_privileged.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:serviceaccounts:kube-system"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:serviceaccounts:${kubernetes_namespace.monitoring.metadata[0].name}"
  }
}

// Make the current & monitoring account allowed to use privileged psp
resource "kubernetes_cluster_role_binding" "psp_privileged_binding" {
  metadata {
    name      = "psp-privileged-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.psp_privileged.metadata[0].name
  }
  subject {
    kind      = "User"
    name      = aws_iam_user.k8s_monitoring.name
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "User"
    name      = data.aws_caller_identity.current.user_id
    api_group = "rbac.authorization.k8s.io"
  }
}

