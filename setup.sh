#!/bin/bash

# --- CONFIGURATION UTF-8 ---
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# --- COULEURS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}>>> INITIALISATION DU PROTOCOLE (Mode: 🚀 Ultimate UTF-8)${NC}"
echo ""

# --- URL AUTO-DETECT ---
if [ -z "$CODESPACE_NAME" ]; then
    API_URL="http://localhost:4566"
else
    API_URL="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
    echo -e "${BLUE}ℹ️  Environnement Codespace détecté.${NC}"
    echo -e "${BLUE}🌍 URL Cible : ${API_URL}${NC}"
fi
echo ""

# Installation silencieuse
echo -ne "📦 ${BLUE}[1/5] Vérification des outils AWS...${NC}"
pip install awscli-local > /dev/null 2>&1
echo -e "${GREEN} ✅ OK${NC}"

# 1. Creation EC2
echo -ne "💻 ${BLUE}[2/5] Lancement de l'instance EC2...${NC}"
INSTANCE_ID=$(awslocal ec2 run-instances --image-id ami-ff000000 --count 1 --instance-type t2.micro --query 'Instances[0].InstanceId' --output text)
echo -e "${GREEN} ✅ OK ($INSTANCE_ID)${NC}"

# 2. Role IAM
echo -ne "🛡️  ${BLUE}[3/5] Sécurisation IAM...${NC}"
awslocal iam delete-role-policy --role-name lambda-ec2-role --policy-name lambda-policy > /dev/null 2>&1 || true
awslocal iam delete-role --role-name lambda-ec2-role > /dev/null 2>&1 || true
awslocal iam create-role --role-name lambda-ec2-role --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null
echo -e "${GREEN} ✅ OK${NC}"

# 3. Code Lambda
echo -ne "🐍 ${BLUE}[4/5] Génération du code Lambda...${NC}"
cat <<EOF > lambda_function.py
import boto3
import json
import os

def lambda_handler(event, context):
    ls_hostname = os.environ.get('LOCALSTACK_HOSTNAME', 'localhost')
    ec2 = boto3.client('ec2', endpoint_url=f"http://{ls_hostname}:4566")
    instance_id = os.environ['INSTANCE_ID']
    path = event.get('resource', '')
    
    msg = ""
    try:
        if '/start' in path:
            ec2.start_instances(InstanceIds=[instance_id])
            msg = "🚀 Démarrage de l'instance initié avec succès."
        elif '/stop' in path:
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = "🛑 Arrêt de l'instance demandé."
        elif '/status' in path:
            msg = "🔍 Vérification de l'état de l'infrastructure..."
        
        desc = ec2.describe_instances(InstanceIds=[instance_id])
        state = desc['Reservations'][0]['Instances'][0]['State']['Name']
        
        return {
            "statusCode": 200, 
            "headers": {"Content-Type": "application/json; charset=utf-8"},
            "body": json.dumps({
                "instance_cible": instance_id, 
                "etat_actuel": state, 
                "message_info": msg
            }, ensure_ascii=False)
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps(str(e))}
EOF
rm -f function.zip
zip function.zip lambda_function.py > /dev/null
echo -e "${GREEN} ✅ OK${NC}"

# 4. Deploiement Lambda & API
echo -ne "☁️  ${BLUE}[5/5] Déploiement API Gateway...${NC}"
awslocal lambda delete-function --function-name ManageEC2 > /dev/null 2>&1 || true

LAMBDA_ARN=$(awslocal lambda create-function \
    --function-name ManageEC2 \
    --zip-file fileb://function.zip \
    --handler lambda_function.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-ec2-role \
    --environment Variables="{INSTANCE_ID=$INSTANCE_ID}" \
    --query 'FunctionArn' --output text)

API_ID=$(awslocal apigateway create-rest-api --name "EC2Controller" --query 'id' --output text)
PARENT_ID=$(awslocal apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

create_route() {
    PATH_PART=$1
    RES_ID=$(awslocal apigateway create-resource --rest-api-id $API_ID --parent-id $PARENT_ID --path-part $PATH_PART --query 'id' --output text)
    awslocal apigateway put-method --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --authorization-type NONE > /dev/null
    awslocal apigateway put-integration --rest-api-id $API_ID --resource-id $RES_ID --http-method GET --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations > /dev/null
}

create_route "start"
create_route "stop"
create_route "status"

awslocal apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null
echo -e "${GREEN} ✅ OK${NC}"

# --- RESULTATS ---
FINAL_URL="${API_URL}/restapis/${API_ID}/prod/_user_request_"

echo ""
echo -e "${YELLOW}==============================================${NC}"
echo -e "${GREEN}      ✅ INSTALLATION TERMINEE (SUCCES)       ${NC}"
echo -e "${YELLOW}==============================================${NC}"
echo ""
echo -e "👇 CLIQUE ICI :"
echo -e "1. STATUT : ${FINAL_URL}/status"
echo -e "2. START  : ${FINAL_URL}/start"
echo -e "3. STOP   : ${FINAL_URL}/stop"
echo ""