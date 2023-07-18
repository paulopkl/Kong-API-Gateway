
create-cluster:
	kind create cluster --config ./kind/clusterconfig.yaml
	kubectl cluster-info --context kind-paulo-kong

destroy-cluster:
	kind delete cluster --name paulo-kong

install-kong:
	-helm repo add kong https://charts.konghq.com
	-helm repo update
	-kubectl create namespace kong
	-helm install kong kong/kong -f FC3-kong-automation/infra/kong-k8s/kong/kong-conf.yaml --namespace kong --set proxy.type=NodePort,proxy.http.nodePort=30000,proxy.tls.nodePort=30003 --set ingressController.installCRDs=false --set serviceMonitor.enabled=true --set serviceMonitor.labels.release=promstack
	kubectl get pods -n kong

install-prometheus:
	-helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	-helm repo update
	-kubectl create namespace monitoring
	-helm install prometheus-stack prometheus-community/kube-prometheus-stack -f FC3-kong-automation/infra/kong-k8s/misc/prometheus/prometheus.yaml --namespace monitoring
	kubectl get pods -n monitoring

install-keycloak:
	-helm repo add bitnami https://charts.bitnami.com/bitnami
	-helm repo update
	-kubectl create namespace iam
	helm install keycloak bitnami/keycloak --namespace iam --set auth.adminUser=keycloak,auth.adminPassword=keycloak
	kubectl get pods -n iam

apply-infra:
	-kubectl create namespace bets
	-kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apps/configmaps/ --recursive -n bets
	-kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apps/deployments/ --recursive -n bets
	-kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apps/services/ --recursive -n bets
	-kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apps/hpa/ --recursive -n bets
	kubectl get pods -n bets

apply-kong-infra:
	kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apis/kong-plugins/kong-plugin-ratelimit.yaml -n bets
	kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apis/kong-plugins/kong-global-plugin-prometheus.yaml
	kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apis/kong-plugins/kong-plugin-openid.yaml -n bets
	kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/apis/kong-ingress-bets-api.yaml -n bets

get-token:
	kubectl apply -f FC3-kong-automation/infra/kong-k8s/misc/token/pod.yaml
	kubectl exec -it testcurl -- /bin/sh -n default
	curl --location --request POST 'http://keycloak.iam/realms/bets/protocol/openid-connect/token' \
      --header 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode 'client_id=kong' \
      --data-urlencode 'client_secret=5HqqwY4dlgG69cJC3QFMflBzQJP8iP8O' \
      --data-urlencode 'grant_type=password' \
      --data-urlencode 'username=paulo' \
      --data-urlencode 'password=paulo123' \
      --data-urlencode 'scope=openid'

install-argocd:
	-kubectl create namespace argocd
	kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --namespace argocd
	kubectl get pods -n argocd

install-elastic-search:
	-kubectl create namespace logs
	-helm repo add elastic https://helm.elastic.co
	helm repo update
	helm install elasticsearch elastic/elasticsearch --version=8.5.1 --namespace logs -f FC3-kong-automation/infra/kong-k8s/efk/elastic/elastic-values.yaml
	kubectl get pods -n logs

install-fluentd:
	-helm repo add fluent https://fluent.github.io/helm-charts
	helm repo update
	helm install fluentd fluent/fluentd --namespace logs -f FC3-kong-automation/infra/kong-k8s/efk/fluentd/fluentd-values.yaml

install-kibana:
	-helm repo add elastic https://helm.elastic.co
	helm repo update
	helm install kibana elastic/kibana --version=8.5.1 --namespace logs --set service.type=NodePort --set service.nodePort=31000
	kubectl get pods -n logs

