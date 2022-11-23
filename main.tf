provider "aws" {
   region = "us-east-1"
}
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "publicsubnets" {    
   vpc_id =  aws_vpc.demo.id
   cidr_block = "10.0.2.0/23"        
}                 
resource "aws_subnet" "privatesubnet1" {
   vpc_id =  aws_vpc.demo.id
   cidr_block = "10.0.4.0/23"          
}
                 
resource "aws_subnet" "privatesubnet2" {
   vpc_id =  aws_vpc.demo.id
   cidr_block = "10.0.6.0/23"
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "my-Igw"
  }
}
resource "aws_route_table" "table" {
  vpc_id = "${aws_vpc.demo.id}"
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}
resource "aws_security_group" "standard-sg" {
  name        = "standard-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["76.124.96.76/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-1"
  }
}
resource "aws_instance" "ec2-instance" {

    #aws_vpc = aws_vpc.Standard-Vpc.id
    subnet_id     = aws_subnet.publicsubnets.id
    ami = "ami-0b0dcb5067f052a63"
   instance_type = "t2.micro"
   count = 1
   key_name = "mine-keypair"
   vpc_security_group_ids = [aws_security_group.standard-sg.id]
user_data = <<EOF
    ! /bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "The page was created by the user data" | sudo tee /var/www/html/index.html
EOF

 # security_group_id    = aws_security_group.standard-sg.id
  tags = {
    "name" = "first Ec2 instance"
  }
}
resource "aws_security_group" "standard-sg02" {
  name        = "standard-sg02"
  description = "Allow only 3306 inbound traffic"
  vpc_id      = aws_vpc.demo.id
ingress {
    description      = "TLS from VPC"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.standard-sg.id]
  }
}
  resource "aws_db_subnet_group" "my-subnet01" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.privatesubnet1.id,aws_subnet.privatesubnet2.id]
    tags = {
    Name = "rds subnet"
  }
}

resource "aws_db_parameter_group" "basic" {
  name   = "mysql"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
resource "aws_db_instance" "mp-sql" {
  
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t3.micro"
  username             = "mike"
  password             = "MeghanaSai!"
  parameter_group_name = aws_db_parameter_group.basic.name
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.my-subnet01.id
 vpc_security_group_ids = [aws_security_group.standard-sg02.id]
}