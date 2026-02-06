#!/bin/bash

echo "[INFO] Demarrage de l'installation (Architecture Multi-URLs)..."

# Installation silencieuse
pip install awscli-local > /dev/null 2>&1

# 1. Creation de l'instance EC2
echo "[1/5] Creation de l'instance EC2..."
INSTANCE_ID=$(awslocal ec2 run-instances \
    --image-id ami-ff000000 \
    --count 1 \
    --instance-type t2.micro \
    --query 'Instances[0].InstanceId' \
    --output text)

echo " -> Instance creee : $INSTANCE_ID"

# 2. Creation du Role IAM
echo "[2/5] Creation du Role IAM..."
awslocal iam create-role --role-name lambda-ec2-role --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null

# 3. Preparation du code Lambda (Logique de Routing)
echo "[3/5] Generation du code Python..."
cat <<EOF > lambda_function.py
import boto3
import json
import os

def lambda_handler(event, context):
    ls_hostname = os.environ.get('LOCALSTACK_HOSTNAME', 'localhost')
    ec2 = boto3.client('ec2', endpoint_url=f"http://{ls_hostname}:4566")
    instance_id = os.environ['INSTANCE_ID']
    
    # On recupere le chemin de l'URL (ex: /start)
    path = event.get('resource', '')
    
    msg = ""
    status_info = ""

    try:
        if '/start' in path:
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"Action START executee sur {instance_id}"
        
        elif '/stop' in path:
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = f"Action STOP executee sur {instance_id}"
            
        elif '/status' in path:
            msg = "Verification du statut..."
        
        else:
            return {"statusCode": 400, "body": json.dumps("Chemin inconnu")}

        # On recupere le statut actuel pour l'afficher
        desc = ec2.describe_instances(InstanceIds=[instance_id])
        state = desc['Reservations'][0]['Instances'][0]['State']['Name']
        
        return {
            "statusCode": 200, 
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "action_demandee": path,
                "instance_id": instance_id,
                "etat_actuel": state,
                "message": msg
            })
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps(str(e))}
EOF

rm -f function.zip
zip function.zip lambda_function.py > /dev/null

# 4. Deploiement de la Lambda
echo "[4/5] Deploiement de la Lambda..."
LAMBDA_ARN=$(awslocal lambda create-function \
    --function-name ManageEC2 \
    --zip-file fileb://function.zip \
    --handler lambda_function.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-ec2-role \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID}" \
    --query 'FunctionArn' --output text)

# 5. Configuration API Gateway (3 Routes : Start, Stop, Status)
echo "[5/5] Configuration API Gateway (Start, Stop, Status)..."
API_ID=$(awslocal apigateway create-rest-api --name "EC2Controller" --query 'id' --output text)
PARENT_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

# Fonction pour creer une route
create_route() {
    PATH_PART=$1
    echo " -> Creation de la route /$PATH_PART"
    RES_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_ID --path-part $PATH_PART --query 'id' --output text)
    
    # On met GET pour pouvoir tester direct dans le navigateur
    awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --authorization-type NONE > /dev/null
    
    awslocal apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $RES_ID \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations > /dev/null
}

create_route "start"
create_route "stop"
create_route "status"

# Deploiement en stage 'prod' comme demande par le prof
awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null

echo "--------------------------------------------------"
echo "[SUCCESS] INSTALLATION TERMINEE"
echo "--------------------------------------------------"
echo "Voici vos 3 URLs de pilotage (Remplacez <VOTRE_URL_GITHUB> par votre URL publique) :"
echo ""
echo "1. DEMARRER :"
echo "https://effective-space-xylophone-wrv44p9pjp6w35xq9-4566.app.github.dev/restapis/$API_ID/prod/_user_request_/start"
echo ""
echo "2. ARRETER :"
echo "https://effective-space-xylophone-wrv44p9pjp6w35xq9-4566.app.github.dev/restapis/$API_ID/prod/_user_request_/stop"
echo ""
echo "3. STATUT :"
echo "https://effective-space-xylophone-wrv44p9pjp6w35xq9-4566.app.github.dev/restapis/$API_ID/prod/_user_request_/status"
echo "--------------------------------------------------"