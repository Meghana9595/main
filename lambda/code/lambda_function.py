import boto3
def lambda_handler (event, context) :
    s3 = boto3.resource('s3')
    s3.create_bucket(Bucket ='mbpacha01')
    #bucket = s3.Bucket('mbpacha01')
