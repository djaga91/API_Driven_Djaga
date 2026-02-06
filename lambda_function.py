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
