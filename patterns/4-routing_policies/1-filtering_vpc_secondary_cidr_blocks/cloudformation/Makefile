.PHONY: deploy deploy-cloudwan deploy-workloads undeploy undeploy-workloads undeploy-cloudwan

deploy: deploy-cloudwan deploy-workloads

deploy-cloudwan:
	aws cloudformation deploy --stack-name core-network-filter-secondary-vpc --template-file core_network.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-filter-secondary-vpc" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-filter-secondary-vpc" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name filter-secondary-vpc-ireland --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name filter-secondary-vpc-nvirginia --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1

undeploy: undeploy-workloads undeploy-cloudwan

undeploy-workloads:
	aws cloudformation delete-stack --stack-name filter-secondary-vpc-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name filter-secondary-vpc-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name filter-secondary-vpc-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name filter-secondary-vpc-nvirginia --region us-east-1

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-filter-secondary-vpc --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-filter-secondary-vpc --region us-east-1
