.PHONY: deploy deploy-cwan deploy-workloads undeploy undeploy-workloads undeploy-cloudwan

deploy: deploy-cwan deploy-workloads

deploy-cwan:
	aws cloudformation deploy --stack-name core-network-outb-ew-dualhop --template-file core_network.yaml --no-fail-on-empty-changeset --region us-east-1

deploy-workloads: CORENETWORK_ID = $(shell aws cloudformation describe-stacks --stack-name "core-network-outb-ew-dualhop" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkId`].OutputValue' --output text --region us-east-1 )
deploy-workloads: CORENETWORK_ARN = $(shell aws cloudformation describe-stacks --stack-name "core-network-outb-ew-dualhop" --query 'Stacks[0].Outputs[?OutputKey == `CoreNetworkArn`].OutputValue' --output text --region us-east-1 )
deploy-workloads:
	aws cloudformation deploy --stack-name outb-ew-dualhop-ireland --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region eu-west-1
	aws cloudformation deploy --stack-name outb-ew-dualhop-nvirginia --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-east-1
	aws cloudformation deploy --stack-name outb-ew-dualhop-oregon --template-file workloads.yaml --parameter-overrides CoreNetworkId="$(CORENETWORK_ID)" CoreNetworkArn="$(CORENETWORK_ARN)" --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --region us-west-2

undeploy: undeploy-workloads undeploy-cloudwan

undeploy-workloads:
	aws cloudformation delete-stack --stack-name outb-ew-dualhop-ireland --region eu-west-1
	aws cloudformation delete-stack --stack-name outb-ew-dualhop-nvirginia --region us-east-1
	aws cloudformation delete-stack --stack-name outb-ew-dualhop-oregon --region us-west-2
	aws cloudformation wait stack-delete-complete --stack-name outb-ew-dualhop-ireland --region eu-west-1
	aws cloudformation wait stack-delete-complete --stack-name outb-ew-dualhop-nvirginia --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name outb-ew-dualhop-oregon --region us-west-2

undeploy-cloudwan:
	aws cloudformation delete-stack --stack-name core-network-outb-ew-dualhop --region us-east-1
	aws cloudformation wait stack-delete-complete --stack-name core-network-outb-ew-dualhop --region us-east-1
