.PHONY: deploy deploy-cloudwan deploy-prefixlist deploy-workloads update-cloudwan undeploy undeploy-workloads undeploy-cloudwan undeploy-prefixlist undeploy-update-cloudwan

deploy: deploy-cloudwan deploy-prefixlist deploy-workloads update-cloudwan

deploy-cloudwan:
	aws cloudformation deploy --stack-name core-network-summarization --template-file base_policy.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-prefixlist: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-summarization" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )

deploy-prefixlist:
	aws cloudformation deploy --stack-name summarization-prefix-list --template prefix_list.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" --no-fail-on-empty-changeset --region us-west-2

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-summarization" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-summarization" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name summarization-ireland --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name summarization-nvirginia --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1

update-cloudwan:
	aws cloudformation update-stack --stack-name core-network-summarization --template-body file://core_network.yaml --region us-east-1
	aws cloudformation wait stack-update-complete --stack-name core-network-summarization --region us-east-1

undeploy: undeploy-workloads undeploy-update-cloudwan undeploy-prefixlist undeploy-cloudwan

undeploy-workloads:
	aws cloudformation delete-stack --stack-name summarization-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name summarization-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name summarization-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name summarization-nvirginia --region us-east-1

undeploy-update-cloudwan:
	aws cloudformation update-stack --stack-name core-network-summarization --template-body file://base_policy.yaml --region us-east-1
	aws cloudformation wait stack-update-complete --stack-name core-network-summarization --region us-east-1

undeploy-prefixlist:
	aws cloudformation delete-stack --stack-name summarization-prefix-list --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name summarization-prefix-list --region us-west-2

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-summarization --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-summarization --region us-east-1
