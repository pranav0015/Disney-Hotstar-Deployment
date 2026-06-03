# DEFINE ALL YOUR VARIABLES HERE

instance_type = "t2.large"
ami           = "ami-07a00cf47dbbc844c"   # Ubuntu 24.04
key_name      = "devops-project-key-pair" # Replace with your key-name without .pem extension
volume_size   = 30
region_name   = "ap-south-1"
server_name   = "jenkins-server"

# Note: 
# a. First create a pem-key manually from the AWS console
# b. Copy it in the same directory as your terraform code