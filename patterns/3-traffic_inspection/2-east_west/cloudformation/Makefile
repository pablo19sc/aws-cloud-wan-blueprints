.PHONY: deploy-dualhop deploy-singlehop deploy-cwan-dualhop deploy-cwan-singlehop deploy-workloads undeploy undeploy-workloads undeploy-cloudwan

deploy-dualhop: deploy-cwan-dualhop deploy-workloads

deploy-singlehop: deploy-cwan-singlehop deploy-workloads

deploy-cwan-dualhop:
	aws cloudformation deploy --stack-name core-network-east-west --template-file core_network_dualhop.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-cwan-singlehop:
	aws cloudformation deploy --stack-name core-network-east-west --template-file core_network_singlehop.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-east-west" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-east-west" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name east-west-ireland --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name east-west-nvirginia --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1
	aws cloudformation deploy --stack-name east-west-oregon --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

undeploy: undeploy-workloads undeploy-cloudwan

undeploy-workloads:
	aws cloudformation delete-stack --stack-name east-west-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name east-west-nvirginia --region us-east-1
	aws cloudformation delete-stack --stack-name east-west-oregon --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name east-west-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name east-west-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name east-west-oregon --region us-west-2

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-east-west --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-east-west --region us-east-1
