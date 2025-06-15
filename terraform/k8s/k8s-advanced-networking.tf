# Install Cilium Network Policy Provider
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.15.1"
  namespace  = "kube-system"

  set {
    name  = "kubeProxyReplacement"
    value = "strict"
  }

  set {
    name  = "k8sServiceHost"
    value = trimprefix(data.azurerm_kubernetes_cluster.this.kube_config.0.host, "https://")
  }

  set {
    name  = "k8sServicePort"
    value = "443"
  }

  set {
    name  = "hubble.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  set {
    name  = "encryption.enabled"
    value = "true"
  }

  set {
    name  = "encryption.type"
    value = "wireguard"
  }
}

# Install Istio Service Mesh
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.20.0"
  namespace  = kubernetes_namespace_v1.istio_system.metadata[0].name

  depends_on = [kubernetes_namespace_v1.istio_system]
}

resource "kubernetes_namespace_v1" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      "istio-injection" = "disabled"
    }
  }
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.20.0"
  namespace  = kubernetes_namespace_v1.istio_system.metadata[0].name

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_gateway" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.20.0"
  namespace  = kubernetes_namespace_v1.istio_system.metadata[0].name

  depends_on = [helm_release.istiod]
}

# Install OPA Gatekeeper for policy enforcement
resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = "3.14.0"
  namespace  = kubernetes_namespace_v1.gatekeeper_system.metadata[0].name

  depends_on = [kubernetes_namespace_v1.gatekeeper_system]
}

resource "kubernetes_namespace_v1" "gatekeeper_system" {
  metadata {
    name = "gatekeeper-system"
  }
}

# Example Network Policy for blog namespace
resource "kubernetes_manifest" "cilium_network_policy_blog" {
  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "blog-access-policy"
      namespace = "blog"
    }
    spec = {
      endpointSelector = {
        matchLabels = {
          app = "blog"
        }
      }
      ingress = [
        {
          fromEndpoints = [
            {
              matchLabels = {
                "io.kubernetes.pod.namespace" = "istio-system"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                {
                  port     = "2368"
                  protocol = "TCP"
                }
              ]
            }
          ]
        }
      ]
      egress = [
        {
          toEndpoints = [
            {
              matchLabels = {
                app = "mysql"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                {
                  port     = "3306"
                  protocol = "TCP"
                }
              ]
            }
          ]
        },
        {
          toFQDNs = [
            {
              matchPattern = "*.drones-shuttles.org"
            }
          ]
          toPorts = [
            {
              ports = [
                {
                  port     = "443"
                  protocol = "TCP"
                }
              ]
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.cilium]
}
