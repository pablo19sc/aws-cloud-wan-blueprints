.PHONY: deploy deploy-cloudwan deploy-workloads deploy-inspection undeploy undeploy-resources undeploy-cloudwan

deploy: deploy-cloudwan deploy-workloads deploy-inspection

deploy-cloudwan:
	aws cloudformation deploy --stack-name core-network-inspection-after-filter --template-file core_network.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-inspection-after-filter" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-inspection-after-filter" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name inspection-after-filter-workload-ireland --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name inspection-after-filter-workload-nvirginia --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1

deploy-inspection: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-inspection-after-filter" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-inspection: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-inspection-after-filter" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-inspection:
	aws cloudformation deploy --stack-name inspection-after-filter-inspection-ireland --template-file inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name inspection-after-filter-inspection-nvirginia --template-file inspection.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1

undeploy: undeploy-resources undeploy-cloudwan

undeploy-resources:
	aws cloudformation delete-stack --stack-name inspection-after-filter-workload-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name inspection-after-filter-workload-nvirginia --region us-east-1
	aws cloudformation delete-stack --stack-name inspection-after-filter-inspection-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name inspection-after-filter-inspection-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name inspection-after-filter-workload-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name inspection-after-filter-workload-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name inspection-after-filter-inspection-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name inspection-after-filter-inspection-nvirginia --region us-east-1

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-inspection-after-filter --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-inspection-after-filter --region us-east-1
