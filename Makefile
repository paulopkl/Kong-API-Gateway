
install-elastic-search:
	-kubectl create namespace logs
	-helm repo add elastic https://helm.elastic.co
	helm repo update
	helm install elasticsearch elastic/elasticsearch --version=8.5.1 --namespace=logs -f FC3-kong-automation/infra/kong-k8s/efk/elastic/elastic-values.yaml

install-fluentd:
	-helm repo add fluent https://fluent.github.io/helm-charts
	helm repo update
	helm install fluentd fluent/fluentd --namespace logs -f FC3-kong-automation/infra/kong-k8s/efk/fluentd/fluentd-values.yaml

install-kibana:
	-helm repo add elastic https://helm.elastic.co
	helm repo update
	helm install kibana elastic/kibana --version=8.5.1 --namespace logs --set service.type=NodePort --set service.nodePort=31000

